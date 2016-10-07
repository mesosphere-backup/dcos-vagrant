# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'lib/vagrant-dcos'
require 'yaml'

## User Config
##############################################

class UserConfig
  attr_accessor :box
  attr_accessor :box_url
  attr_accessor :box_version
  attr_accessor :machine_config_path
  attr_accessor :config_path
  attr_accessor :generate_config_path
  attr_accessor :install_method
  attr_accessor :vagrant_mount_method
  attr_accessor :java_enabled
  attr_accessor :private_registry

  def self.from_env
    c = new
    c.box                  = ENV.fetch('DCOS_BOX', 'mesosphere/dcos-centos-virtualbox')
    c.box_url              = ENV.fetch('DCOS_BOX_URL', 'https://downloads.dcos.io/dcos-vagrant/metadata.json')
    c.box_version          = ENV.fetch('DCOS_BOX_VERSION', '~> 0.8.0')
    c.machine_config_path  = ENV.fetch('DCOS_MACHINE_CONFIG_PATH', 'VagrantConfig.yaml')
    c.config_path          = ENV.fetch('DCOS_CONFIG_PATH', 'etc/config.yaml')
    c.generate_config_path = ENV.fetch('DCOS_GENERATE_CONFIG_PATH', 'dcos_generate_config.sh')
    c.install_method       = ENV.fetch('DCOS_INSTALL_METHOD', 'ssh_pull')
    c.vagrant_mount_method = ENV.fetch('DCOS_VAGRANT_MOUNT_METHOD', 'virtualbox')
    c.java_enabled         = (ENV.fetch('DCOS_JAVA_ENABLED', 'false') == 'true')
    c.private_registry     = (ENV.fetch('DCOS_PRIVATE_REGISTRY', 'false') == 'true')
    c
  end

  # validate required fields and files
  def validate
    errors = []

    # Validate required fields
    required_fields = [
      :box,
      :box_url,
      :box_version,
      :machine_config_path,
      :config_path,
      :generate_config_path,
      :install_method,
      :vagrant_mount_method
    ]
    required_fields.each do |field_name|
      field_value = send(field_name.to_sym)
      if field_value.nil? || field_value.empty?
        errors << "Missing required attribute: #{field_name}"
      end
    end

    return errors unless errors.empty?

    # Validate required files
    required_files = [
      :machine_config_path,
      :generate_config_path,
      :config_path
    ]
    required_files.each do |field_name|
      file_path = send(field_name.to_sym)
      unless File.file?(file_path)
        errors << "File not found: '#{file_path}'. Ensure that the file exists or reconfigure its location (export #{env_var(field_name)}=<value>)"
      end
    end

    errors
  end

  # create environment for provisioning scripts
  def provision_env(machine_type)
    env = {
      'DCOS_CONFIG_PATH' => path_to_url(@config_path),
      'DCOS_GENERATE_CONFIG_PATH' => path_to_url(@generate_config_path),
      'DCOS_JAVA_ENABLED' => @java_enabled ? 'true' : 'false',
      'DCOS_PRIVATE_REGISTRY' => @private_registry ? 'true' : 'false'
    }
    if machine_type['memory-reserved']
      env['DCOS_TASK_MEMORY'] = machine_type['memory'] - machine_type['memory-reserved']
    end
    env
  end

  protected

  # resolve relative paths to be relative to the vagrant mount (allow remote urls)
  def path_to_url(path)
    %r{^\w*:\/\/} =~ path ? path : 'file:///vagrant/' + path
  end

  # convert field symbol to env var
  def env_var(field)
    "DCOS_#{field.to_s.upcase}"
  end
end

## Plugin Validation
##############################################

def validate_plugins
  required_plugins = [
    'vagrant-hostmanager'
  ]
  missing_plugins = []

  required_plugins.each do |plugin|
    unless Vagrant.has_plugin?(plugin)
      missing_plugins << "The '#{plugin}' plugin is required. Install it with 'vagrant plugin install #{plugin}'"
    end
  end

  unless missing_plugins.empty?
    missing_plugins.each { |x| STDERR.puts x }
    return false
  end

  true
end

def validate_machine_types(machine_types)
  boot_types = machine_types.select { |_, cfg| cfg['type'] == 'boot' }
  if boot_types.empty?
    STDERR.puts 'Must have at least one machine of type boot'
    exit 2
  end

  master_types = machine_types.select { |_, cfg| cfg['type'] == 'master' }
  if master_types.empty?
    STDERR.puts 'Must have at least one machine of type master'
    exit 2
  end

  agent_types = machine_types.select { |_, cfg| cfg['type'] == 'agent-private' || cfg['type'] == 'agent-public' }
  if agent_types.empty?
    STDERR.puts 'Must have at least one machine of type agent-private or agent-public'
    exit 2
  end
end

def raise_errors(errors)
  STDERR.puts 'Errors:'
  errors.each do |error|
    STDERR.puts "  #{error}"
  end
  exit 2
end

# path to the provision shell scripts
def provision_script_path(type)
  "./provision/bin/#{type}.sh"
end

## One Time Setup
##############################################

if Vagrant::VERSION == '1.8.5'
  ui = Vagrant::UI::Colored.new
  ui.error 'Unsupported Vagrant Version: 1.8.5'
  ui.error 'For more info, visit https://github.com/dcos/dcos-vagrant/blob/master/docs/troubleshooting.md#ssh-authentication-failure'
  ui.error ''
end

Vagrant.require_version '>= 1.8.4', '!= 1.8.5'

if Vagrant::VERSION == '1.8.6'
  # Monkey patch for network interface detection bug in Vagrant 1.8.6
  # https://github.com/mitchellh/vagrant/issues/7876
  require_relative 'lib/linux_network_interfaces'
end

validate_plugins || exit(1)

# parse and validate environment
user_config = UserConfig.from_env
errors = user_config.validate
raise_errors(errors) unless errors.empty?

# parse and validate machine config
machine_types = YAML.load_file(Pathname.new(user_config.machine_config_path).realpath)
validate_machine_types(machine_types)

# configure vbox host-only network
system(provision_script_path('vbox-network'))


## VM Creation & Provisioning
##############################################

Vagrant.configure(2) do |config|

  # configure vagrant-hostmanager plugin
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false

  # Avoid random ssh key for demo purposes
  config.ssh.insert_key = false
  
  # Vagrant Plugin Configuration: vagrant-vbguest
  if Vagrant.has_plugin?('vagrant-vbguest')
    # enable auto update guest additions
    config.vbguest.auto_update = true
  end

  machine_types.each do |name, machine_type|
    config.vm.define name do |machine|
      machine.vm.hostname = "#{name}.dcos"

      # custom hostname aliases
      if machine_type['aliases']
        machine.hostmanager.aliases = machine_type['aliases'].join(' ').to_s
      end

      # custom mount type
      machine.vm.synced_folder '.', '/vagrant', type: user_config.vagrant_mount_method

      # allow explicit nil values in the machine_type to override the defaults
      machine.vm.box = machine_type.fetch('box', user_config.box)
      machine.vm.box_url = machine_type.fetch('box-url', user_config.box_url)
      machine.vm.box_version = machine_type.fetch('box-version', user_config.box_version)

      machine.vm.provider 'virtualbox' do |v, override|
        v.name = machine.vm.hostname
        v.cpus = machine_type['cpus'] || 2
        v.memory = machine_type['memory'] || 2048
        v.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']

        override.vm.network :private_network, ip: machine_type['ip']
      end

      # Hack to remove loopback host alias that conflicts with vagrant-hostmanager
      # https://dcosjira.atlassian.net/browse/VAGRANT-15
      machine.vm.provision :shell, inline: "sed -i'' '/^127.0.0.1\\t#{machine.vm.hostname}\\t#{name}$/d' /etc/hosts"

      # provision a shared SSH key (required by DC/OS SSH installer)
      machine.vm.provision :dcos_ssh, name: 'Shared SSH Key'

      machine.vm.provision :shell do |vm|
        vm.name = 'Certificate Authorities'
        vm.path = provision_script_path('ca-certificates')
      end

      machine.vm.provision :shell do |vm|
	    vm.name = 'Install Probe'
        vm.path = provision_script_path('install-probe')
      end

      machine.vm.provision :shell do |vm|
        vm.name = 'Install jq'
        vm.path = provision_script_path('install-jq')
      end

      machine.vm.provision :shell do |vm|
        vm.name = 'Install DC/OS Postflight'
        vm.path = provision_script_path('install-postflight')
      end

      case machine_type['type']
      when 'agent-private', 'agent-public'
        machine.vm.provision :shell do |vm|
          vm.name = 'Install Mesos Memory Modifier'
          vm.path = provision_script_path('install-mesos-memory')
        end
      end

      if user_config.private_registry
        machine.vm.provision :shell do |vm|
          vm.name = 'Start Private Docker Registry'
          vm.path = provision_script_path('insecure-registry')
        end
      end

      script_path = provision_script_path("type-#{machine_type['type']}")
      if File.exist?(script_path)
        machine.vm.provision :shell do |vm|
          vm.name = "DC/OS #{machine_type['type'].capitalize}"
          vm.path = script_path
          vm.env = user_config.provision_env(machine_type)
        end
      end

      if machine_type['type'] == 'boot'
        # install DC/OS after boot machine is provisioned
        machine.vm.provision :dcos_install do |dcos|
          dcos.install_method = user_config.install_method
          dcos.machine_types = machine_types
          dcos.config_template_path = user_config.config_path
        end
      end
    end
  end
end
