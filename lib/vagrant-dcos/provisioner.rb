# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'executor'
require_relative 'errors'
require_relative '../../vendor/semi_semantic/lib/semi_semantic/version'
require 'thread'
require 'yaml'
require 'uri'
require 'open-uri'
require 'time'

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
          @config.license_key_contents,
          @config.max_install_threads,
        )
      end

      protected

      # execute remote command as root
      # print command, stdout, and stderr (indented)
      def remote_sudo(machine, command, opts=nil, &block)
        prefix = '      '
        machine.ui.info("[sudo]$ #{command.chomp.gsub(/\n/, "\n#{prefix}")}")
        machine.communicate.sudo(command, opts) do |type, data|
          if data.chomp.length > 0
            # inject line prefixes
            output = prefix + data.chomp.gsub(/\n/, "\n#{prefix}")
            # uncolorize
            output = output.gsub(/\e\[([;\d]+)?m/, '')
            case type
            when :stdout
              machine.ui.detail(output)
            when :stderr
              machine.ui.warn(output)
            end
          end
          yield(type, data) if block
        end
      end

      # execute remote command as root on machine being provisioned
      def sudo(command, opts=nil, &block)
        remote_sudo(@machine, command, opts, &block)
      end

      def dcos_version()
        return @dcos_version if @dcos_version

        # Run inside `~/dcos` to cache output (tarball, genconf dir) for future runs.
        version_json = ''
        exit_code = sudo('cd ~/dcos && bash ~/dcos/dcos_generate_config.sh --version', error_check: false) do |type, data|
          version_json << data if type == :stdout
        end
        if exit_code != 0
          # `--version` was added in 1.8
          # TODO: remove fallback once 1.7 support is dropped
          @dcos_version = SemiSemantic::Version.parse('0.0.0-unknown')
          return @dcos_version
        end
        version_json = version_json.chomp

        # trim lines before start of the json hash (stdout is messy)
        json_start = version_json.index(/^{$/)
        version_json = version_json[json_start..-1]

        # Parse json as yaml (yaml is a superset of json)
        @dcos_version = SemiSemantic::Version.parse(YAML.load(version_json)['version'])
        @dcos_variant = YAML.load(version_json)['variant']
        @machine.ui.info "Setting variant #{@dcos_variant}"

        @dcos_version
      end

      def install(machine_types, config_template_path, install_method, license_key_contents, max_install_threads)
        @machine.ui.info "Installing DC/OS #{dcos_version}"

        @machine.ui.info "Reading #{config_template_path}"
        gen_conf_config = YAML.load_file(Pathname.new(config_template_path).realpath)

        @machine.ui.info 'Analyzing machines'
        gen_conf_config['master_list'] = []

        # cache active machine lookup
        active_machines = @machine.env.active_machines

        # configure how to access the nodes from the boot machine
        gen_conf_config['master_list'] = machine_ips(active_machines, machine_types, 'master')
        gen_conf_config['agent_list'] = machine_ips(active_machines, machine_types, 'agent-private')
        gen_conf_config['public_agent_list'] = machine_ips(active_machines, machine_types, 'agent-public')

        # validate version/configuration compatibility
        # TODO: remove check once 1.7 support is dropped
        if [:ssh_push, :web].include?(install_method) && gen_conf_config['public_agent_list'].length > 0 && dcos_version < SemiSemantic::Version.parse('1.8.0')
          raise InstallError.new("Public agents are not supported by install method '#{install_method}' prior to DC/OS 1.8.0")
        end

        if @dcos_variant == 'ee'
          gen_conf_config['fault_domain_enabled'] = 'false'
          gen_conf_config['license_key_contents'] = license_key_contents
        end

        # configure how to access the boot machine from the nodes
        boot_address = find_address(@machine)
        gen_conf_config['exhibitor_zk_hosts'] = "#{boot_address}:2181"
        case install_method
        when :ssh_push, :web
          # TODO: in the future this may not be required by genconf, since it's really an internal concern
          gen_conf_config['bootstrap_url'] = 'file:///opt/dcos_install_tmp'
        when :ssh_pull
          # url to the nginx server that will host the output of genconf
          gen_conf_config['bootstrap_url'] = "http://#{boot_address}"
        end

        # configure how the nodes will resolve domains
        case @machine.provider_name
        when :aws
          gen_conf_config['resolvers'] = ['169.254.169.253']
        else # :virtualbox
          # default to VirtualBox's NAT DNS Host Resolver
          gen_conf_config['resolvers'] ||= ['10.0.2.3']
        end

        @machine.ui.info 'Generating Configuration: ~/dcos/genconf/config.yaml'
        write_gen_conf_config(gen_conf_config)

        @machine.ui.info 'Generating IP Detection Script: ~/dcos/genconf/ip-detect'
        master_ip = gen_conf_config['master_list'].first
        write_ip_detect(master_ip)

        @machine.ui.info 'Importing Private SSH Key: ~/dcos/genconf/ssh_key'
        sudo('cp /vagrant/.vagrant/dcos/private_key_vagrant ~/dcos/genconf/ssh_key')

        if install_method == :web
          # Move config files to the /vagrant mount so the user can reference/upload them to the web ui
          sudo('mkdir -p /vagrant/dcos')
          sudo('mv ~/dcos/genconf/config.yaml /vagrant/dcos/config.yaml')
          sudo('mv ~/dcos/genconf/ip-detect /vagrant/dcos/ip-detect')
          start_web_installer
          installer_address = "http://#{@machine.config.vm.hostname}:9000"
          unless probe_address(installer_address)
            @machine.ui.error 'Timed out waiting for the Web Installer to start'
            sudo('systemctl status dcos-installer')
            raise InstallError.new('Timed out waiting for the Web Installer to start')
          end
          @machine.ui.info "DC/OS Web Installer Available: #{installer_address}"
          @machine.ui.info "Example config: dcos/config.yaml"
          @machine.ui.info "Example ip-detect: dcos/ip-detect"
          return
        end

        @machine.ui.info 'Generating DC/OS Installer Files: ~/dcos/genconf/serve/'
        sudo('cd ~/dcos && bash ~/dcos/dcos_generate_config.sh --genconf && cp -rpv ~/dcos/genconf/serve/* /var/tmp/dcos/ && echo ok > /var/tmp/dcos/ready')

        case install_method
        when :ssh_push
          install_push
        when :ssh_pull
          install_pull(active_machines, machine_types, max_install_threads)
        end

        @machine.ui.success "DC/OS Installation Complete\nWeb Interface: http://m1.dcos/"
      end

      def filter_machines(active_machines, machine_types, type)
        active_machines.select { |name, _provider| machine_types[name.to_s]['type'] == type }
      end

      def start_web_installer
        service_start_path = '/usr/local/bin/dcos-installer'
        service_start = <<-EOF
#!/usr/bin/env bash
cd /root/dcos
exec bash /root/dcos/dcos_generate_config.sh --web
EOF

        escaped_service_start = service_start.gsub('$', '\$')

        @machine.ui.info "Generating Installer Script: #{service_start_path}"
        sudo(%(cat << EOF > #{service_start_path}\n#{escaped_service_start}\nEOF))
        sudo("chmod u+x #{service_start_path}")

        service_config_path = '/etc/systemd/system/dcos-installer.service'
        service_config = <<-EOF
[Unit]
Description=DC/OS Web Installer
After=docker.service
Requires=docker.service

[Service]
Type=simple
ExecStart=#{service_start_path}
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

        escaped_service_config = service_config.gsub('$', '\$')

        @machine.ui.info "Generating Installer Service: #{service_config_path}"
        sudo(%(cat << EOF > #{service_config_path}\n#{escaped_service_config}\nEOF))
        sudo('systemctl daemon-reload && systemctl enable dcos-installer')

        @machine.ui.info "Starting Installer Service"
        sudo('systemctl start dcos-installer')
      end

      def probe_address(address)
        # 2 minute timeout
        timeout = Time.now + (60 * 2)

        until Time.now > timeout do
          machine.ui.output("Probing #{address} ...")
          begin
            open(address) do |file|
              # ignore response
            end
            return true
          rescue OpenURI::HTTPError, Errno::ECONNREFUSED => error
            sleep(5)
          end
        end

        # timeout exceeded
        return false
      end

      def install_push
        sudo('cd ~/dcos && bash ~/dcos/dcos_generate_config.sh --preflight')
        sudo('cd ~/dcos && bash ~/dcos/dcos_generate_config.sh --deploy')
        sudo('cd ~/dcos && bash ~/dcos/dcos_generate_config.sh --postflight')
      end

      def install_pull(active_machines, machine_types, max_install_threads)
        # install masters in parallel
        queue = Queue.new
        filter_machines(active_machines, machine_types, 'master').each do |name, provider|
          machine = @machine.env.machine(name, provider)
          queue.push(Proc.new do
            machine.ui.info 'Installing DC/OS (master)'
            remote_sudo(machine, %(bash -ceu "curl --fail --location --silent --show-error --verbose http://boot.dcos/dcos_install.sh | bash -s -- master"))
          end)
        end
        Executor.exec(queue, max_install_threads)

        # install agents (public and private) in parallel
        queue = Queue.new
        filter_machines(active_machines, machine_types, 'agent-private').each do |name, provider|
          machine = @machine.env.machine(name, provider)
          queue.push(Proc.new do
            machine.ui.info 'Installing DC/OS (agent)'
            remote_sudo(machine, %(bash -ceu "curl --fail --location --silent --show-error --verbose http://boot.dcos/dcos_install.sh | bash -s -- slave"))
          end)
        end
        filter_machines(active_machines, machine_types, 'agent-public').each do |name, provider|
          machine = @machine.env.machine(name, provider)
          queue.push(Proc.new do
            machine.ui.info 'Installing DC/OS (agent-public)'
            remote_sudo(machine, %(bash -ceu "curl --fail --location --silent --show-error --verbose http://boot.dcos/dcos_install.sh | bash -s -- slave_public"))
          end)
        end
        Executor.exec(queue, max_install_threads)

        # postflight all nodes in parallel
        # reconfigure agent memory after postflight
        queue = Queue.new
        filter_machines(active_machines, machine_types, 'master').each do |name, provider|
          machine = @machine.env.machine(name, provider)
          queue.push(Proc.new do
            machine.ui.info 'DC/OS Postflight'
            remote_sudo(machine, 'dcos-postflight')
          end)
        end
        filter_machines(active_machines, machine_types, 'agent-private').each do |name, provider|
          machine = @machine.env.machine(name, provider)
          queue.push(Proc.new do
            machine.ui.info 'DC/OS Postflight'
            remote_sudo(machine, 'dcos-postflight')
            if machine_types[name.to_s]['memory-reserved']
              memory = machine_types[name.to_s]['memory'] - machine_types[name.to_s]['memory-reserved']
              machine.ui.info "Setting Mesos Memory: #{memory} (role=*)"
              remote_sudo(machine, %(mesos-memory #{memory}))
              machine.ui.info 'Restarting Mesos Agent'
              remote_sudo(machine, %(bash -ceu "systemctl stop dcos-mesos-slave.service && rm -f /var/lib/mesos/slave/meta/slaves/latest && systemctl start dcos-mesos-slave.service --no-block"))
            end
          end)
        end
        filter_machines(active_machines, machine_types, 'agent-public').each do |name, provider|
          machine = @machine.env.machine(name, provider)
          queue.push(Proc.new do
            machine.ui.info 'DC/OS Postflight'
            remote_sudo(machine, 'dcos-postflight')
            if machine_types[name.to_s]['memory-reserved']
              memory = machine_types[name.to_s]['memory'] - machine_types[name.to_s]['memory-reserved']
              machine.ui.info "Setting Mesos Memory: #{memory} (role=slave_public)"
              remote_sudo(machine, %(mesos-memory #{memory} slave_public))
              machine.ui.info 'Restarting Mesos Agent'
              remote_sudo(machine, %(bash -ceu "systemctl stop dcos-mesos-slave-public.service && rm -f /var/lib/mesos/slave/meta/slaves/latest && systemctl start dcos-mesos-slave-public.service --no-block"))
            end
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
        escaped_config_yaml = YAML.dump(gen_conf_config).gsub('$', '\$')
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

        sudo(%(cat << 'EOF' > ~/dcos/genconf/ip-detect\n#{ip_config}\nEOF))
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

        raise InstallError.new("Failed to find IP address of machine: #{machine.config.vm.name}")
      end
    end
  end
end
