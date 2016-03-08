# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'gen_conf_config'
require 'yaml'

module VagrantPlugins
  module DCOS
    class Provisioner < Vagrant.plugin(2, :provisioner)

      def configure(root_config)
      end

      def provision
        install(
          @config.machine_types,
          @config.config_template_path,
          @config.parallel,
        )
      end

      def cleanup()
      end

      protected

      # execute remote command as root
      # print command, stdout, and stderr (indented)
      def remote_sudo(machine, command)
        prefix = '      '
        machine.ui.output("sudo: #{command.chomp.gsub(/\n/,"\n#{prefix}")}")
        machine.communicate.sudo(command) do |type, data|
          output = prefix + data.chomp.gsub(/\n/,"\n#{prefix}")
          case type
          when :stdout
            machine.ui.output(output)
          when :stderr
            machine.ui.error(output)
          end
        end
      end

      # execute remote command as root on machine being provisioned
      def sudo(command)
        remote_sudo(@machine, command)
      end

      def install(machine_types, config_template_path, parallel)
        @machine.ui.info "Reading #{config_template_path}"
        gen_conf_config = GenConfConfigLoader.load_file(Pathname.new(config_template_path).realpath)

        @machine.ui.info 'Analyzing machines'
        gen_conf_config.master_list = []

        # cache active machine lookup
        active_machines = @machine.env.active_machines

        # 1.7 adds --version
        #sudo('bash ~/dcos/dcos_generate_config.sh --version')

        update_gen_conf_config(gen_conf_config, active_machines, machine_types)

        # required config for SSH deploy
        if parallel
          # "cluster_config.bootstrap_url must be set to 'file:///opt/dcos_install_tmp' to use the SSH deploy utilities."
          gen_conf_config.bootstrap_url = 'file:///opt/dcos_install_tmp'
        end

        write_gen_conf_config(gen_conf_config)

        master_ip = gen_conf_config.master_list.first
        write_ip_detect(master_ip)

        @machine.ui.info 'Importing ~/dcos/genconf/ssh_key'
        sudo('cp /vagrant/.vagrant/dcos/private_key_vagrant ~/dcos/genconf/ssh_key')
        #sudo('cat ~/dcos/genconf/ssh_key')

        sudo('cd ~/dcos && bash ~/dcos/dcos_generate_config.sh --genconf && cp -rpv ~/dcos/genconf/serve/* /var/tmp/dcos/')

        if parallel
          install_parallel
        else
          install_serial(active_machines, machine_types)
        end

        0
      end

      def filter_machines(active_machines, machine_types, type)
        active_machines.select{ |name, _provider| machine_types[name.to_s]['type'] == type }
      end

      def install_parallel
        sudo('cd ~/dcos && bash ~/dcos/dcos_generate_config.sh --preflight')
        sudo('cd ~/dcos && bash ~/dcos/dcos_generate_config.sh --deploy')
        sudo('cd ~/dcos && bash ~/dcos/dcos_generate_config.sh --postflight')
      end

      def install_serial(active_machines, machine_types)

        filter_machines(active_machines, machine_types, 'master').each do |name, provider|
          machine = @machine.env.machine(name, provider)
          machine.ui.info 'Installing DCOS (master)'
          remote_sudo(machine, %Q(bash -c "curl --fail --location --silent --show-error --verbose http://boot.dcos/dcos_install.sh | bash -s -- master"))
        end

        filter_machines(active_machines, machine_types, 'agent-private').each do |name, provider|
          machine = @machine.env.machine(name, provider)
          machine.ui.info 'Installing DCOS (agent)'
          remote_sudo(machine, %Q(bash -c "curl --fail --location --silent --show-error --verbose http://boot.dcos/dcos_install.sh | bash -s -- slave"))
        end

        filter_machines(active_machines, machine_types, 'agent-public').each do |name, provider|
          machine = @machine.env.machine(name, provider)
          machine.ui.info 'Installing DCOS (agent-public)'
          remote_sudo(machine, %Q(bash -c "curl --fail --location --silent --show-error --verbose http://boot.dcos/dcos_install.sh | bash -s -- slave_public"))
        end

        # postflight masters
        filter_machines(active_machines, machine_types, 'master').each do |name, provider|
          machine = @machine.env.machine(name, provider)
          machine.ui.info 'DCOS Postflight'
          write_postflight(machine)
          remote_sudo(machine, '/opt/mesosphere/bin/postflight.sh')
        end

        # postflight agent-private
        filter_machines(active_machines, machine_types, 'agent-private').each do |name, provider|
          machine = @machine.env.machine(name, provider)
          machine.ui.info 'DCOS Postflight'
          write_postflight(machine)
          remote_sudo(machine, '/opt/mesosphere/bin/postflight.sh')
        end

        # postflight agent-public
        filter_machines(active_machines, machine_types, 'agent-public').each do |name, provider|
          machine = @machine.env.machine(name, provider)
          machine.ui.info 'DCOS Postflight'
          write_postflight(machine)
          remote_sudo(machine, '/opt/mesosphere/bin/postflight.sh')
        end

      end

      # update gen_conf_config with public addresses from the active machines
      def update_gen_conf_config(gen_conf_config, active_machines, machine_types)
        master_list = []
        agent_list = []

        active_machines.each do |name, provider|
          case machine_types[name.to_s]['type']
          when 'boot'
            machine = @machine.env.machine(name, provider)
            public_address = machine.provider.capability(:public_address)
            gen_conf_config.exhibitor_zk_hosts = "#{public_address}:2181"
            gen_conf_config.bootstrap_url = "http://#{public_address}"
          when 'master'
            machine = @machine.env.machine(name, provider)
            public_address = machine.provider.capability(:public_address)
            master_list.push(public_address)
          when 'agent-private'
            machine = @machine.env.machine(name, provider)
            public_address = machine.provider.capability(:public_address)
            agent_list.push(public_address)
          when 'agent-public'
            machine = @machine.env.machine(name, provider)
            public_address = machine.provider.capability(:public_address)
            agent_list.push(public_address)
          end
        end

        # push all at once to simplify gen_conf_config impl (pushing onto a generated array won't work)
        gen_conf_config.master_list = master_list
        gen_conf_config.agent_list = agent_list
      end

      # write config.yaml to the boot machine
      def write_gen_conf_config(gen_conf_config)
        escaped_config_yaml = gen_conf_config.to_yaml.gsub('$', '\$')
        @machine.ui.info 'Generating ~/dcos/genconf/config.yaml'
        sudo(%Q(cat << EOF > ~/dcos/genconf/config.yaml\n#{escaped_config_yaml}\nEOF))
      end

      # write ip-detect to the boot machine
      def write_ip_detect(master_ip)
        ip_config = <<-EOF
#!/usr/bin/env bash
set -o errexit
set -o nounset
set -o pipefail
echo $(/usr/sbin/ip route show to match #{master_ip} | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | tail -1)
EOF

        escaped_ip_config = ip_config.gsub('$', '\$')

        @machine.ui.info 'Generating ~/dcos/genconf/ip-detect'
        sudo(%Q(cat << EOF > ~/dcos/genconf/ip-detect\n#{escaped_ip_config}\nEOF))
      end

      # from https://github.com/mesosphere/dcos-installer/blob/master/dcos_installer/action_lib/__init__.py#L250
      # TODO: hopefully this goes away at some point so we dont have to write a looping postflight check
      def write_postflight(machine)
        postflight = <<-EOF
#!/usr/bin/env bash
# Run the DCOS diagnostic script for up to 15 minutes (900 seconds) to ensure
# we do not return ERROR on a cluster that hasn't fully achieved quorum.
T=900
until OUT=$(/opt/mesosphere/bin/dcos-diagnostics.py) || [[ T -eq 0 ]]; do
    sleep 1
    let T=T-1
done
RETCODE=$?
for value in $OUT; do
    echo $value
done
exit $RETCODE
EOF

        escaped_postflight = postflight.gsub('$', '\$')

        machine.ui.info 'Generating /opt/mesosphere/bin/postflight.sh'
        remote_sudo(machine, %Q(cat << EOF > /opt/mesosphere/bin/postflight.sh\n#{escaped_postflight}\nEOF))
        remote_sudo(machine, 'chmod u+x /opt/mesosphere/bin/postflight.sh')
      end

    end
  end
end
