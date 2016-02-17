# -*- mode: ruby -*-
# vi: set ft=ruby :

require "yaml"


## Config
##############################################

$user_config = {
  box:            ENV.fetch("DCOS_BOX", "mesosphere/dcos-centos-virtualbox"),
  box_url:        ENV.fetch("DCOS_BOX_URL", "https://downloads.mesosphere.com/dcos-vagrant/metadata.json"),
  box_version:    ENV.fetch("DCOS_BOX_VERSION", "~> 0.3"),

  vm_config_path:       ENV.fetch("DCOS_VM_CONFIG_PATH", "VagrantConfig.yaml"),
  config_path:          ENV.fetch("DCOS_CONFIG_PATH", "etc/1_master-config-1.5.yaml"),
  generate_config_path: ENV.fetch("DCOS_GENERATE_CONFIG_PATH", "dcos_generate_config.sh"),
  java_enabled:         ENV.fetch("DCOS_JAVA_ENABLED", "false"),
  private_registry:     ENV.fetch("DCOS_PRIVATE_REGISTRY", "false"),
}


## Config File Validation
##############################################

def validate_config_files()
  required_files = {
    "DCOS_VM_CONFIG_PATH" => $user_config[:vm_config_path],
    "DCOS_GENERATE_CONFIG_PATH" => $user_config[:generate_config_path],
    "DCOS_CONFIG_PATH" => $user_config[:config_path],
  }
  missing_files = []

  required_files.each do |env_var, file_path|
    unless File.file?(file_path)
      missing_files << "File not found: '#{file_path}'. Ensure that the file exists or reconfigure its location with 'export #{env_var}=<path>'"
    end
  end

  unless missing_files.empty?
    missing_files.each{ |x| STDERR.puts x }
    return false
  end

  return true
end

validate_config_files || exit


## VM Config
##############################################

$vagrant_config = YAML::load_file($user_config[:vm_config_path])


## VM Config Validation
##############################################

def master_ips()
  $vagrant_config.select{ |_, cfg| cfg["type"] == "master" }.map{ |_, cfg| cfg["ip"] }
end

def validate_vm_config()
  if master_ips.empty?
    STDERR.puts "vm config must contain at least one vm of type master"
    return false
  end

  return true
end

validate_vm_config || exit


## Provision Environment
##############################################

def vagrant_path(path)
  if ! /^\w*:\/\//.match(path)
    path = "file:///vagrant/" + path
  end
  return path
end

$provision_environment = {
  "DCOS_CONFIG_PATH" => vagrant_path($user_config[:config_path]),
  "DCOS_GENERATE_CONFIG_PATH" => vagrant_path($user_config[:generate_config_path]),
  "DCOS_JAVA_ENABLED" => $user_config[:java_enabled],
  "DCOS_PRIVATE_REGISTRY" => $user_config[:private_registry],
  "DCOS_MASTER_IPS" => master_ips.join(" "),
}

def provision_path(type)
  return "./provision/bin/#{type}.sh"
end


## Plugin Validation
##############################################

def validate_plugins()
  required_plugins = [
    "vagrant-hostmanager",
    "vagrant-vbguest",
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

validate_plugins || exit


## VM Creation & Provisioning
##############################################

Vagrant.configure(2) do |config|

  # configure the vagrant-hostmanager plugin
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false

  # configure the vagrant-vbguest plugin
  config.vbguest.auto_update = true

  $vagrant_config.each do |name,cfg|
    config.vm.define name do |vm_cfg|
      vm_cfg.vm.hostname = "#{name}.dcos"
      vm_cfg.vm.network "private_network", ip: cfg["ip"]

      # custom hostname aliases
      if cfg["aliases"]
        vm_cfg.hostmanager.aliases = %Q(#{cfg["aliases"].join(" ")})
      end

      # allow explicit nil values in the cfg to override the defaults
      vm_cfg.vm.box = cfg.fetch("box", $user_config[:box])
      vm_cfg.vm.box_url = cfg.fetch("box-url", $user_config[:box_url])
      vm_cfg.vm.box_version = cfg.fetch("box-version", $user_config[:box_version])

      vm_cfg.vm.provider "virtualbox" do |v|
        v.name = vm_cfg.vm.hostname
        v.cpus = cfg["cpus"] || 2
        v.memory = cfg["memory"] || 2048
        v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      end

      if cfg["forwards"]
        cfg["forwards"].each do |from,to|
          vm_config.vm.forward_port from, to
        end
      end

      vm_cfg.vm.provision "shell", name: "Certificate Authorities", path: provision_path("ca-certificates")
      if $user_config[:private_registry] == "true"
        vm_cfg.vm.provision "shell", name: "Private Docker Registry", path: provision_path("insecure-registry")
      end
      if cfg["type"]
        vm_cfg.vm.provision "shell", name: "DCOS #{cfg['type'].capitalize}", path: provision_path("type-#{cfg["type"]}"), env: $provision_environment
      end
    end
  end
end
