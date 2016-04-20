# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'gen_conf_config'
require_relative 'executor'
require 'thread'
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
          @config.install_method.to_sym,
          @config.max_install_threads,
          @config.postflight_timeout_seconds
        )
      end

      def cleanup
      end

      protected

      # execute remote command as root
      # print command, stdout, and stderr (indented)
      def remote_sudo(machine, command)
        prefix = '      '
        machine.ui.output("sudo: #{command.chomp.gsub(/\n/, "\n#{prefix}")}")
        machine.communicate.sudo(command) do |type, data|
          output = prefix + data.chomp.gsub(/\n/, "\n#{prefix}")
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

      def install(machine_types, config_template_path, install_method, max_install_threads, postflight_timeout_seconds)
        @machine.ui.info "Reading #{config_template_path}"
        gen_conf_config = GenConfConfigLoader.load_file(config_template_path)

        @machine.ui.info 'Analyzing machines'
        gen_conf_config.master_list = []

        # cache active machine lookup
        active_machines = @machine.env.active_machines

        # 1.7 adds --version
        # sudo('bash ~/dcos/dcos_generate_config.sh --version')

        # configure how to access the nodes from the boot machine
        gen_conf_config.master_list = machine_ips(active_machines, machine_types, 'master')
        gen_conf_config.agent_list = machine_ips(active_machines, machine_types, 'agent-private') + machine_ips(active_machines, machine_types, 'agent-public')

        # configure how to access the boot machine from the nodes
        boot_address = find_address(@machine)
        gen_conf_config.exhibitor_zk_hosts = "#{boot_address}:2181"
        case install_method
        when :ssh_push
          # TODO: in the future this may not be required by genconf, since it's really an internal concern
          gen_conf_config.bootstrap_url = 'file:///opt/dcos_install_tmp'
        when :ssh_pull
          # url to the nginx server that will host the output of genconf
          gen_conf_config.bootstrap_url = "http://#{boot_address}"
        end

        # configure how the nodes will resolve domains
        case @machine.provider_name
        when :aws
          gen_conf_config.resolvers = ['169.254.169.253']
        else # :virtualbox
          gen_conf_config.resolvers ||= ['8.8.8.8']
        end

        @machine.ui.success 'Generating Configuration: ~/dcos/genconf/config.yaml'
        write_gen_conf_config(gen_conf_config)

        @machine.ui.success 'Generating IP Detection Script: ~/dcos/genconf/ip-detect'
        master_ip = gen_conf_config.master_list.first
        write_ip_detect(master_ip)

        @machine.ui.success 'Importing Private SSH Key: ~/dcos/genconf/ssh_key'
        sudo('cp /vagrant/.vagrant/dcos/private_key_vagrant ~/dcos/genconf/ssh_key')
        # sudo('cat ~/dcos/genconf/ssh_key')

        @machine.ui.success 'Generating DC/OS Installer Files: ~/dcos/genconf/serve/'
        sudo('cd ~/dcos && bash ~/dcos/dcos_generate_config.sh --genconf && cp -rpv ~/dcos/genconf/serve/* /var/tmp/dcos/')

        case install_method
        when :ssh_push
          install_push
        when :ssh_pull
          install_pull(active_machines, machine_types, max_install_threads, postflight_timeout_seconds)
        end

        @machine.ui.success "DC/OS Installation Complete\nWeb Interface: http://m1.dcos/"
      end

      def filter_machines(active_machines, machine_types, type)
        active_machines.select { |name, _provider| machine_types[name.to_s]['type'] == type }
      end

      def install_push
        sudo('cd ~/dcos && bash ~/dcos/dcos_generate_config.sh --preflight')
        sudo('cd ~/dcos && bash ~/dcos/dcos_generate_config.sh --deploy')
        sudo('cd ~/dcos && bash ~/dcos/dcos_generate_config.sh --postflight')
      end

      def install_pull(active_machines, machine_types, max_install_threads, postflight_timeout_seconds)
        # install masters in parallel
        queue = Queue.new
        filter_machines(active_machines, machine_types, 'master').each do |name, provider|
          machine = @machine.env.machine(name, provider)
          queue.push(Proc.new do
            machine.ui.success 'Installing DC/OS (master)'
            remote_sudo(machine, %(bash -c "curl --fail --location --silent --show-error --verbose http://boot.dcos/dcos_install.sh | bash -s -- master"))
          end)
        end
        Executor.exec(queue, max_install_threads)

        # install agents (public and private) in parallel
        queue = Queue.new
        filter_machines(active_machines, machine_types, 'agent-private').each do |name, provider|
          machine = @machine.env.machine(name, provider)
          queue.push(Proc.new do
            machine.ui.success 'Installing DC/OS (agent)'
            remote_sudo(machine, %(bash -c "curl --fail --location --silent --show-error --verbose http://boot.dcos/dcos_install.sh | bash -s -- slave"))
          end)
        end
        filter_machines(active_machines, machine_types, 'agent-public').each do |name, provider|
          machine = @machine.env.machine(name, provider)
          queue.push(Proc.new do
            machine.ui.success 'Installing DC/OS (agent-public)'
            remote_sudo(machine, %(bash -c "curl --fail --location --silent --show-error --verbose http://boot.dcos/dcos_install.sh | bash -s -- slave_public"))
          end)
        end
        Executor.exec(queue, max_install_threads)

        # postflight all nodes in parallel
        queue = Queue.new
        filter_machines(active_machines, machine_types, 'master').each do |name, provider|
          machine = @machine.env.machine(name, provider)
          queue.push(Proc.new do
            machine.ui.success 'DC/OS Postflight'
            write_postflight(machine, postflight_timeout_seconds)
            remote_sudo(machine, '/opt/mesosphere/bin/postflight.sh')
          end)
        end
        filter_machines(active_machines, machine_types, 'agent-private').each do |name, provider|
          machine = @machine.env.machine(name, provider)
          queue.push(Proc.new do
            machine.ui.success 'DC/OS Postflight'
            write_postflight(machine, postflight_timeout_seconds)
            remote_sudo(machine, '/opt/mesosphere/bin/postflight.sh')
          end)
        end
        filter_machines(active_machines, machine_types, 'agent-public').each do |name, provider|
          machine = @machine.env.machine(name, provider)
          queue.push(Proc.new do
            machine.ui.success 'DC/OS Postflight'
            write_postflight(machine, postflight_timeout_seconds)
            remote_sudo(machine, '/opt/mesosphere/bin/postflight.sh')
          end)
        end
        Executor.exec(queue, max_install_threads)
      end

      def machine_ips(active_machines, machine_types, type)
        ip_list = []
        filter_machines(active_machines, machine_types, type).each do |name, provider|
          machine = @machine.env.machine(name, provider)
          ip_list.push(find_address(machine))
        end
        ip_list
      end

      # write config.yaml to the boot machine
      def write_gen_conf_config(gen_conf_config)
        escaped_config_yaml = gen_conf_config.to_yaml.gsub('$', '\$')
        sudo(%(cat << EOF > ~/dcos/genconf/config.yaml\n#{escaped_config_yaml}\nEOF))
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

        sudo(%(cat << EOF > ~/dcos/genconf/ip-detect\n#{escaped_ip_config}\nEOF))
      end

      # from https://github.com/mesosphere/dcos-installer/blob/master/dcos_installer/action_lib/__init__.py#L250
      # TODO: hopefully this goes away at some point so we dont have to write a looping postflight check
      def write_postflight(machine, postflight_timeout_seconds)
        postflight = <<-EOF
#!/usr/bin/env bash
# Run the DC/OS diagnostic script for up to #{postflight_timeout_seconds} seconds to ensure
# we do not return ERROR on a cluster that hasn't fully achieved quorum.
if [[ -e "/opt/mesosphere/bin/3dt" ]]; then
    # DC/OS >= 1.7
    CMD="/opt/mesosphere/bin/3dt -diag"
elif [[ -e "/opt/mesosphere/bin/dcos-diagnostics.py" ]]; then
    # DC/OS <= 1.6
    CMD="/opt/mesosphere/bin/dcos-diagnostics.py"
else
    echo "Postflight Failure: either 3dt or dcos-diagnostics.py must be present"
    exit 1
fi
T=#{postflight_timeout_seconds}
until OUT=$(${CMD} 2>&1) || [[ T -eq 0 ]]; do
    sleep 5
    let T=T-5
done
RETCODE=$?
if [[ "${RETCODE}" != "0" ]]; then
    echo "DC/OS Unhealthy\n${OUT}" >&2
fi
exit ${RETCODE}
EOF

        escaped_postflight = postflight.gsub('$', '\$')

        machine.ui.success 'Generating Postflight Script: /opt/mesosphere/bin/postflight.sh'
        remote_sudo(machine, %(cat << EOF > /opt/mesosphere/bin/postflight.sh\n#{escaped_postflight}\nEOF))
        remote_sudo(machine, 'chmod u+x /opt/mesosphere/bin/postflight.sh')
      end

      def find_address(machine)
        # public address
        address = machine.provider.capability(:public_address)
        return address if address && address != '127.0.0.1'

        # private address
        machine.config.vm.networks.each do |network|
          key = network[0]
          options = network[1]
          if key == :private_network
            address = options[:ip]
            return address if address
          end
        end

        raise AddressResolutionError.new(machine.config.vm.name)
      end
    end
  end
end
