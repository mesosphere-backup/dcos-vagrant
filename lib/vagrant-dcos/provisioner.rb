# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

module VagrantPlugins
  module DCOS
    class Provisioner < Vagrant.plugin(2, :provisioner)

      def configure(root_config)
      end

      def provision
        install(@config.machine_types, @config.config_template_path)
      end

      def cleanup()
      end

      protected

      # execute command as root
      # print command, stdout, and stderr (indented)
      def sudo(command)
        prefix = '      '
        @machine.ui.output("sudo: #{command.chomp.gsub(/\n/,"\n#{prefix}")}")
        @machine.communicate.sudo(command) do |type, data|
          output = prefix + data.chomp.gsub(/\n/,"\n#{prefix}")
          case type
          when :stdout
            @machine.ui.output(output)
          when :stderr
            @machine.ui.error(output)
          end
        end
      end

      def install(machine_types, config_template_path)
        @machine.ui.info "Reading #{config_template_path}"
        installer_config = YAML::load_file(Pathname.new(config_template_path).realpath)

        # Detect 1.5
        #if (installer_config['cluster_config'])
        #  dcos_version = 1.5
        #  #TODO: Support 1.5
        #else
        #  dcos_version = 1.6
        #end

        @machine.ui.info 'Analyzing machines'
        installer_config['master_list'] = []

        # cache active machine lookup
        active_machines = @machine.env.active_machines

        # 1.7 adds --version
        #sudo('bash ~/dcos/dcos_generate_config.sh --version')

        update_installer_config(installer_config, active_machines, machine_types)
        write_installer_config(installer_config)

        master_ip = installer_config['master_list'].first
        write_ip_detect(master_ip)

        @machine.ui.info 'Importing ~/dcos/genconf/ssh_key'
        sudo('cp /vagrant/.vagrant/dcos/private_key_vagrant ~/dcos/genconf/ssh_key')
        #sudo('cat ~/dcos/genconf/ssh_key')

        sudo('cd ~/dcos && bash ~/dcos/dcos_generate_config.sh --genconf && cp -rpv ~/dcos/genconf/serve/* /var/tmp/dcos/')

        #install_manual(active_machines, machine_types)
        install_auto()

        0
      end

      def install_auto
        sudo('cd ~/dcos && bash ~/dcos/dcos_generate_config.sh --preflight')
        sudo('cd ~/dcos && bash ~/dcos/dcos_generate_config.sh --deploy')
        sudo('cd ~/dcos && bash ~/dcos/dcos_generate_config.sh --postflight')
      end

      def install_manual(active_machines, machine_types)
        active_machines.each do |name, provider|
          case machine_types[name.to_s]['type']
          when 'master'
            machine = @machine.env.machine(name, provider)
            @machine.ui.info 'Installing DCOS master on #{name}'
            sudo(%Q(bash -c "curl --fail --location --silent --show-error --verbose http://boot.dcos/dcos_install.sh | bash -s -- master"))
          when 'agent-private'
            machine = @machine.env.machine(name, provider)
            @machine.ui.info 'Installing DCOS agent on #{name}'
            sudo(%Q(bash -c "curl --fail --location --silent --show-error --verbose http://boot.dcos/dcos_install.sh | bash -s -- slave"))
          when 'agent-public'
            machine = @machine.env.machine(name, provider)
            @machine.ui.info 'Installing DCOS agent-public on #{name}'
            sudo(%Q(bash -c "curl --fail --location --silent --show-error --verbose http://boot.dcos/dcos_install.sh | bash -s -- slave_public"))
          end
        end
      end

      # update installer_config with public addresses from the active machines
      def update_installer_config(installer_config, active_machines, machine_types)
        active_machines.each do |name, provider|
          #puts "Found Machine: #{name} - #{provider}: #{machine_types[name.to_s]}"
          case machine_types[name.to_s]['type']
          when 'boot'
            machine = @machine.env.machine(name, provider)
            public_address = machine.provider.capability(:public_address)
            installer_config['exhibitor_zk_hosts'] = "#{public_address}:2181"
            installer_config['bootstrap_url'] = "http://#{public_address}"
          when 'master'
            machine = @machine.env.machine(name, provider)
            public_address = machine.provider.capability(:public_address)
            installer_config['master_list'].push(public_address)
          when 'agent-private'
            machine = @machine.env.machine(name, provider)
            public_address = machine.provider.capability(:public_address)
            installer_config['agent_list'].push(public_address)
          when 'agent-public'
            machine = @machine.env.machine(name, provider)
            public_address = machine.provider.capability(:public_address)
            installer_config['agent_list'].push(public_address)
          end
        end
      end

      # write config.yaml to the boot machine
      def write_installer_config(installer_config)
        #puts installer_config.to_yaml

        escaped_config_yaml = installer_config.to_yaml.gsub('$', '\$')

        @machine.ui.info 'Generating ~/dcos/genconf/config.yaml'
        sudo(%Q(cat << EOF > ~/dcos/genconf/config.yaml\n#{escaped_config_yaml}\nEOF))
        #sudo('cat ~/dcos/genconf/config.yaml')
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
        #puts ip_config
        escaped_ip_config = ip_config.gsub('$', '\$')

        @machine.ui.info 'Generating ~/dcos/genconf/ip-detect'
        sudo(%Q(cat << EOF > ~/dcos/genconf/ip-detect\n#{escaped_ip_config}\nEOF))
        #sudo('cat ~/dcos/genconf/ip-detect')
      end

    end
  end
end
