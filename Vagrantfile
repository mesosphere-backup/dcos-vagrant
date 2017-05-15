# -*- mode: ruby -*-
# vi: set ft=ruby :

require_relative 'lib/vagrant-dcos'
require 'vagrant/util/downloader'
require 'vagrant/ui'
require 'yaml'
require 'fileutils'
require 'digest'

class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def blue
    colorize(34)
  end

  def pink
    colorize(35)
  end

  def light_blue
    colorize(36)
  end
end

require 'log4r/config'
UI = Log4r::Logger.new("dcos-vagrant")
UI.add Log4r::Outputter.stdout
if ENV['VAGRANT_LOG'] && ENV['VAGRANT_LOG'] != ''
  Log4r.define_levels(*Log4r::Log4rConfig::LogLevels)
  level = Log4r.const_get(ENV['VAGRANT_LOG'].upcase)
  UI.level = level
end

## User Config
##############################################

class UserConfig
  attr_accessor :box
  attr_accessor :box_url
  attr_accessor :box_version
  attr_accessor :machine_config_path
  attr_accessor :config_path
  attr_accessor :version
  attr_accessor :generate_config_path
  attr_accessor :install_method
  attr_accessor :vagrant_mount_method
  attr_accessor :java_enabled
  attr_accessor :private_registry

  def self.from_env
    c = new
    c.box                  = ENV.fetch(env_var('box'), 'mesosphere/dcos-centos-virtualbox')
    c.box_url              = ENV.fetch(env_var('box_url'), 'https://downloads.dcos.io/dcos-vagrant/metadata.json')
    c.box_version          = ENV.fetch(env_var('box_version'), '~> 0.9.0')
    c.machine_config_path  = ENV.fetch(env_var('machine_config_path'), 'VagrantConfig.yaml')
    c.config_path          = ENV.fetch(env_var('config_path'), '')
    c.version              = ENV.fetch(env_var('version'), '')
    c.generate_config_path = ENV.fetch(env_var('generate_config_path'), '')
    c.install_method       = ENV.fetch(env_var('install_method'), 'ssh_pull')
    c.vagrant_mount_method = ENV.fetch(env_var('vagrant_mount_method'), 'virtualbox')
    c.java_enabled         = (ENV.fetch(env_var('java_enabled'), 'false') == 'true')
    c.private_registry     = (ENV.fetch(env_var('private_registry'), 'false') == 'true')
    c
  end

  # resolve relative paths to be relative to the vagrant mount (allow remote urls)
  def self.path_to_url(path)
    %r{^\w*:\/\/} =~ path ? path : 'file:///vagrant/' + path
  end

  # convert field symbol to env var
  def self.env_var(field)
    "DCOS_#{field.to_s.upcase}"
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
      :install_method,
      :vagrant_mount_method
    ]
    required_fields.each do |field_name|
      field_value = send(field_name.to_sym)
      if field_value.nil? || field_value.empty?
        errors << "Missing required attribute: #{field_name}"
      end
    end

    raise ValidationError, errors unless errors.empty?

    if @config_path.empty? && !@generate_config_path.empty?
      errors << "Config path (#{UserConfig.env_var('config_path')}) must be specified when installer (#{UserConfig.env_var('generate_config_path')}) is specified."
    end

    # Validate required files
    required_files = []
    required_files << :machine_config_path if !@machine_config_path.empty?
    required_files << :config_path if !@config_path.empty?
    required_files << :generate_config_path if !@config_path.empty?

    required_files.each do |field_name|
      file_path = send(field_name.to_sym)
      field_env_var = UserConfig.env_var(field_name)
      if file_path.empty?
        errors << "File path not specified: '#{field_env_var}'. Ensure that the file path is configured (export #{field_env_var}=<value>)."
        next
      end
      if file_path.start_with?(File::SEPARATOR)
        errors << "File path not relative: '#{file_path}'. Ensure that the path is relative to the repo directory, which is mounted into the VMs (export #{field_env_var}=<value>)."
        next
      end
      unless File.file?(file_path)
        errors << "File not found: '#{file_path}'. Ensure that the file exists or reconfigure its location (export #{field_env_var}=<value>)."
      end
    end

    raise ValidationError, errors unless errors.empty?
  end

  # create environment for provisioning scripts
  def provision_env(machine_type)
    env = {
      'DCOS_CONFIG_PATH' => UserConfig.path_to_url(@config_path),
      'DCOS_GENERATE_CONFIG_PATH' => UserConfig.path_to_url(@generate_config_path),
      'DCOS_JAVA_ENABLED' => @java_enabled ? 'true' : 'false',
      'DCOS_PRIVATE_REGISTRY' => @private_registry ? 'true' : 'false'
    }
    if machine_type['memory-reserved']
      env['DCOS_TASK_MEMORY'] = machine_type['memory'] - machine_type['memory-reserved']
    end
    env
  end
end

class ValidationError < StandardError
  def initialize(list=[], msg="Validation Error")
    @list = list
    super(msg)
  end

  def list
    @list.dup
  end

  def publish
    UI.error 'Errors:'.red
    @list.each do |error|
      UI.error "  #{error}".red
    end
    exit 2
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
    missing_plugins.each { |x| UI.error x }
    return false
  end

  true
end

def validate_machine_types(machine_types)
  boot_types = machine_types.select { |_, cfg| cfg['type'] == 'boot' }
  if boot_types.empty?
    raise ValidationError, ['Must have at least one machine of type boot']
  end

  master_types = machine_types.select { |_, cfg| cfg['type'] == 'master' }
  if master_types.empty?
    raise ValidationError, ['Must have at least one machine of type master']
  end

  agent_types = machine_types.select { |_, cfg| cfg['type'] == 'agent-private' || cfg['type'] == 'agent-public' }
  if agent_types.empty?
    raise ValidationError, ['Must have at least one machine of type agent-private or agent-public']
  end
end

# path to the provision shell scripts
def provision_script_path(type)
  "./provision/bin/#{type}.sh"
end

DCOS_VERSIONS_FILE = 'dcos-versions.yaml'

def load_dcos_versions
  dcos_versions = YAML.load_file(Pathname.new(DCOS_VERSIONS_FILE).realpath)

  #TODO: validate content?
  dcos_versions
end

def validate_installer(path, sha256Expected)
  UI.info "Validating Installer Checksum..."
  sha256 = Digest::SHA256.file(path).hexdigest
  unless sha256Expected == sha256
    errorMsg = "Installer Checksum (SHA256) Mismatch - expected: '#{sha256Expected}'; found: '#{sha256}'"
    UI.warn errorMsg
    raise ValidationError, [errorMsg]
  end
end

def download_installer_version(version, url, path, sha256Expected)
  UI.info "Downloading DC/OS #{version} Installer...".yellow
  UI.info "Source: #{url}"
  UI.info "Destination: #{path}"

  options = {}
  if UI.level <= Log4r::INFO
    options[:ui] = Vagrant::UI::Colored.new
  end
  dl = Vagrant::Util::Downloader.new(url, path, options)

  retriesMax = 3
  retries = 0
  errorMsgs = []
  begin
    File.delete(path) if File.file?(path)
    dl.download!
    validate_installer(path, sha256Expected)

  rescue ValidationError => e
    errorMsgs += e.list
    retry if (retries += 1) < retriesMax
    errorMsgs += ["Maximum download retries exceeded: #{retriesMax}"]
    raise ValidationError, errorMsgs
  end
end

# download installer, if not already downloaded
def download_installer(dcos_versions, version)
  version_meta = dcos_versions['versions'][version]

  if version_meta.nil?
    raise ValidationError, ["Version not found: '#{version}'. See '#{DCOS_VERSIONS_FILE}' for known versions. Either version (#{UserConfig.env_var('version')}) or installer (#{UserConfig.env_var('generate_config_path')}) must be specified via environment variables."]
  end

  url = "https://downloads.dcos.io/dcos/#{version_meta['channel']}/commit/#{version_meta['ref']}/dcos_generate_config.sh"
  path = "installers/dcos/dcos_generate_config-#{version}.sh"
  sha256Expected = version_meta['sha256']

  FileUtils.mkdir_p Pathname.new(path).dirname

  if File.file?(path)
    begin
      validate_installer(path, sha256Expected)
      # valid installer already exists
      return path
    rescue ValidationError
      # stifle first checksum failure, if file already existed
      # delete and re-download (with retries) as if it didn't exist
    end
  end

  download_installer_version(version, url, path, sha256Expected)

  path
end

def config_path(version)
  file_path = "etc/config-#{version}.yaml"
  return file_path if File.file?(file_path)

  if result = version.match(/^([0-9]+\.[0-9]+)/)
    file_path = "etc/config-#{result[1]}.yaml"
    return file_path if File.file?(file_path)
  end

  raise ValidationError, ["No installer config found for version '#{version}' at 'etc/config-#{version}.yaml'. Ensure that the file exists or reconfigure its location (export #{UserConfig.env_var('config_path')}=<value>)."]
end

## One Time Setup
##############################################

def validate_command(machine_types)
  args = ARGV.dup.select { |arg| !arg.start_with?('-') }
  command = args[0]
  args = args[1..-1]

  if command == 'halt'
    machine_names = args.empty? && machine_types.keys || args
    has_master_machine = !machine_names.select { |machine_name| machine_types[machine_name]['type'] == 'master' }.empty?
    if has_master_machine
      UI.error 'Halt command disabled by dcos-vagrant.'.red
      UI.error 'DC/OS Master nodes will not automatically recover from quorum loss.'.red
      UI.error 'Use `vagrant suspend` or `vagrant destroy` instead.'.red
      return false
    end
  end

  true
end

def error_known_good_versions
  UI.error 'Latest known-working versions: Vagrant 1.9.3, VirtualBox 5.1.22'.red
end

# Monkey patches and known-bad Vagrant versions
case Vagrant::VERSION
when '1.9.4'
  if Vagrant::Util::Platform.windows?
    UI.error 'Unsupported Vagrant Version (on Windows): 1.9.4'.red
    UI.error 'For more info, see https://github.com/mitchellh/vagrant/issues/8520'.red
    error_known_good_versions
    Vagrant.require_version '>= 1.8.4', '!= 1.8.5', '!= 1.8.7', '!= 1.9.4'
  end
when '1.9.1'
  require_relative 'vendor/vagrant-patches/redhat_change_host_name_1.9.1'
  require_relative 'vendor/vagrant-patches/redhat_configure_networks_1.9.1'
when '1.8.7'
  UI.error 'Unsupported Vagrant Version: 1.8.7'.red
  UI.error 'For more info, see https://github.com/mitchellh/vagrant/issues/7969'.red
  error_known_good_versions
when '1.8.6'
  require_relative 'vendor/vagrant-patches/linux_network_interfaces_1.8.6'
when '1.8.5'
  UI.error 'Unsupported Vagrant Version: 1.8.5'.red
  UI.error 'For more info, see https://github.com/mitchellh/vagrant/issues/7610'.red
  error_known_good_versions
end

Vagrant.require_version '>= 1.8.4', '!= 1.8.5', '!= 1.8.7'

begin

  UI.info 'Validating Plugins...'
  validate_plugins || exit(1)

  UI.info 'Validating User Config...'
  user_config = UserConfig.from_env
  user_config.validate

  # update installer based on version, unless specified
  if user_config.generate_config_path.empty?
    dcos_versions = load_dcos_versions
    # use latest known, if not specified
    user_config.version = user_config.version.empty? ? dcos_versions['latest'] : user_config.version
    user_config.generate_config_path = download_installer(dcos_versions, user_config.version)
  end
  UI.info "Using DC/OS Installer: #{user_config.generate_config_path}".yellow

  # update config based on version, unless specified
  if user_config.config_path.empty? && !user_config.version.empty?
    user_config.config_path = config_path(user_config.version)
  end
  UI.info "Using DC/OS Config: #{user_config.config_path}".yellow

  UI.info 'Validating Machine Config...'
  machine_types = YAML.load_file(Pathname.new(user_config.machine_config_path).realpath)
  validate_machine_types(machine_types)

  UI.info 'Validating Command...'
  validate_command(machine_types) || exit(1)

rescue ValidationError => e
  e.publish
end

UI.info 'Configuring VirtualBox Host-Only Network...'
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

        # Manually configure DNS
        v.auto_nat_dns_proxy = false
        # NAT proxy is flakey (times out frequently)
        v.customize ['modifyvm', :id, '--natdnsproxy1', 'off']
        # Host DNS resolution required to support host proxies and faster global DNS resolution
        v.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']

        override.vm.network :private_network, ip: machine_type['ip']

        # guest should sync time if more than 10s off host
        v.customize [ "guestproperty", "set", :id, "/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold", 1000 ]
      end

      # Hack to remove loopback host alias that conflicts with vagrant-hostmanager
      # https://jira.mesosphere.com/browse/DCOS_VAGRANT-15
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
