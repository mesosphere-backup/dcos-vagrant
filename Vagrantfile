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
  attr_accessor :java_enabled
  attr_accessor :private_registry

  def self.from_env
    c = self.new
    c.box                  = ENV.fetch('DCOS_BOX', 'mesosphere/dcos-centos-virtualbox')
    c.box_url              = ENV.fetch('DCOS_BOX_URL', 'https://downloads.mesosphere.com/dcos-vagrant/metadata.json')
    c.box_version          = ENV.fetch('DCOS_BOX_VERSION', '~> 0.4.1')
    c.machine_config_path  = ENV.fetch('DCOS_MACHINE_CONFIG_PATH', 'VagrantConfig.yaml')
    c.config_path          = ENV.fetch('DCOS_CONFIG_PATH', 'etc/config.yaml')
    c.generate_config_path = ENV.fetch('DCOS_GENERATE_CONFIG_PATH', 'dcos_generate_config.sh')
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
      :config_path,
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
  def provision_env
    {
      'DCOS_CONFIG_PATH' => path_to_url(@config_path),
      'DCOS_GENERATE_CONFIG_PATH' => path_to_url(@generate_config_path),
      'DCOS_JAVA_ENABLED' => @java_enabled ? 'true' : 'false',
      'DCOS_PRIVATE_REGISTRY' => @private_registry ? 'true' : 'false',
    }
  end

  protected

  # resolve relative paths to be relative to the vagrant mount (allow remote urls)
  def path_to_url(path)
    /^\w*:\/\//.match(path) ? path : 'file:///vagrant/' + path
  end

  # convert field symbol to env var
  def env_var(field)
    "DCOS_#{field.to_s.upcase}"
  end

end



## Plugin Validation
##############################################

def validate_plugins()
  required_plugins = [
    'vagrant-hostmanager',
  ]
  missing_plugins = []

  required_plugins.each do |plugin|
    unless Vagrant.has_plugin?(plugin)
      missing_plugins << "The '#{plugin}' plugin is required. Install it with 'vagrant plugin install #{plugin}'"
    end
  end

  unless missing_plugins.empty?
    missing_plugins.each{ |x| STDERR.puts x }
    return false
  end

  return true
end

def validate_machine_types(machine_types)
  boot_types = machine_types.select{ |_, cfg| cfg['type'] == 'boot' }
  if boot_types.empty?
    STDERR.puts 'Must have at least one machine of type boot'
    exit 2
  end

  master_types = machine_types.select{ |_, cfg| cfg['type'] == 'master' }
  if master_types.empty?
    STDERR.puts 'Must have at least one machine of type master'
    exit 2
  end
end

def raise_errors(errors)
  STDERR.puts "Errors:"
  errors.each do |category, error_list|
    STDERR.puts "  #{category}:"
    error_list.each do |error|
      STDERR.puts "    #{error}"
    end
  end
  exit 2
end

# path to the provision shell scripts
def provision_script_path(type)
  return "./provision/bin/#{type}.sh"
end


## VM Creation & Provisioning
##############################################

Vagrant.configure(2) do |config|

  validate_plugins || exit(1)

  # configure vagrant-hostmanager plugin
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false

  # configure vagrant-vbguest plugin
  if Vagrant.has_plugin?('vagrant-vbguest')
    config.vbguest.auto_update = true
  end


  user_config = UserConfig.from_env

  errors = user_config.validate
  raise_errors(errors) unless errors.empty?

  machine_types =  YAML::load_file(Pathname.new(user_config.machine_config_path).realpath)
  validate_machine_types(machine_types)


  machine_types.each do |name, machine_type|
    config.vm.define name do |machine|

      provision_env = user_config.provision_env

      # configure DNS
      machine.vm.provider 'virtualbox' do
        provision_env['DCOS_DNS_IPS'] = %w( 8.8.8.8 ).join(' ')
      end
      machine.vm.provider 'aws' do
        provision_env['DCOS_DNS_IPS'] = %w( 169.254.169.253 ).join(' ')
      end

      machine.vm.hostname = "#{name}.dcos"

      # custom hostname aliases
      if machine_type['aliases']
        machine.hostmanager.aliases = %Q(#{machine_type['aliases'].join(' ')})
      end

      # Use NFS for shared folders for better performance
      #TODO NFS client install is soooo sloooow...
      #machine.vm.synced_folder '.', '/vagrant', nfs: true

      # allow explicit nil values in the machine_type to override the defaults
      machine.vm.box = machine_type.fetch('box', user_config.box)
      machine.vm.box_url = machine_type.fetch('box-url', user_config.box_url)
      machine.vm.box_version = machine_type.fetch('box-version', user_config.box_version)

      machine.vm.provider 'virtualbox' do |v, override|
        v.name = machine.vm.hostname
        v.cpus = machine_type['cpus'] || 2
        v.memory = machine_type['memory'] || 2048
        v.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']

        override.vm.network 'private_network', ip: machine_type['ip']
      end

      # provision a shared SSH key (required by DCOS SSH installer)
      machine.vm.provision(
        :dcos_ssh,
        name: 'Shared SSH Key',
        preserve_order: true
      )

      machine.vm.provision(
        :shell,
        name: 'Certificate Authorities',
        path: provision_script_path('ca-certificates')
      )

      if user_config.private_registry
        machine.vm.provision(
          :shell,
          name: 'Private Docker Registry',
          path: provision_script_path('insecure-registry')
        )
      end

      # only provision the boot machine
      if machine_type['type'] == 'boot'
        machine.vm.provision(
          :shell,
          name: "DCOS #{machine_type['type'].capitalize}",
          path: provision_script_path("type-#{machine_type['type']}"),
          env: provision_env
        )

        machine.vm.provision(
          :dcos_install,
          machine_types: machine_types,
          config_template_path: user_config.config_path,
          preserve_order: true
        )
      end

    end
  end
end
