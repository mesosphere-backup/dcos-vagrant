# -*- mode: ruby -*-
# vi: set ft=ruby :

require "yaml"


## CONFIG
##############################################

$USER_CONFIG = {
  box:            ENV.fetch("DCOS_BOX", "mesosphere/dcos-centos-virtualbox"),
  box_url:        ENV.fetch("DCOS_BOX_URL", "https://downloads.mesosphere.com/dcos-vagrant/metadata.json"),
  box_version:    ENV.fetch("DCOS_BOX_VERSION", nil),

  vm_config_path:       ENV.fetch("DCOS_VM_CONFIG_PATH", "VagrantConfig.yaml"),
  ip_detect_path:       ENV.fetch("IP_DETECT_PATH", "etc/ip-detect.sh"),
  config_path:          ENV.fetch("DCOS_CONFIG_PATH", "etc/1_master-config.json"),
  generate_config_path: ENV.fetch("DCOS_GENERATE_CONFIG_PATH", "dcos_generate_config.sh"),
  java_enabled:         ENV.fetch("DCOS_JAVA_ENABLED", "false"),
  private_registry:     ENV.fetch("DCOS_PRIVATE_REGISTRY", "false"),
}


## PROVISION ENVIRONMENT
##############################################

def vagrant_path(path)
  if ! /^\w*:\/\//.match(path)
    path = "file:///vagrant/" + path
  end
  return path
end

$PROVISION_ENV = {
  "DCOS_IP_DETECT_PATH" => vagrant_path($USER_CONFIG[:ip_detect_path]),
  "DCOS_CONFIG_PATH" => vagrant_path($USER_CONFIG[:config_path]),
  "DCOS_GENERATE_CONFIG_PATH" => vagrant_path($USER_CONFIG[:generate_config_path]),
  "DCOS_JAVA_ENABLED" => $USER_CONFIG[:java_enabled],
  "DCOS_PRIVATE_REGISTRY" => $USER_CONFIG[:private_registry],
}

def provision_path(type)
  return "./provision/bin/#{type}.sh"
end


#### Validation
##############################################

if !File.file?($USER_CONFIG[:vm_config_path])
  raise "vm config not found: DCOS_VM_CONFIG_PATH=#{$USER_CONFIG[:vm_config_path]}"
end

if !File.file?($USER_CONFIG[:generate_config_path])
  raise "dcos installer not found: DCOS_GENERATE_CONFIG_PATH=#{$USER_CONFIG[:generate_config_path]}"
end

if !File.file?($USER_CONFIG[:config_path])
  raise "dcos config not found: DCOS_CONFIG_PATH=#{$USER_CONFIG[:config_path]}"
end

if !File.file?($USER_CONFIG[:ip_detect_path])
  raise "ip-detect not found: IP_DETECT_PATH=#{$USER_CONFIG[:ip_detect_path]}"
end


#### Setup & Provisioning
##############################################

Vagrant.configure(2) do |config|
  YAML::load_file($USER_CONFIG[:vm_config_path]).each do |name,cfg|
    config.vm.define name do |vm_cfg|
      vm_cfg.vm.hostname = "#{name}.dcos"
      vm_cfg.vm.network "private_network", ip: cfg["ip"]

      # allow explicit nil values in the cfg to override the defaults
      vm_cfg.vm.box = cfg.fetch("box", $USER_CONFIG[:box])
      vm_cfg.vm.box_url = cfg.fetch("box-url", $USER_CONFIG[:box_url])
      vm_cfg.vm.box_version = cfg.fetch("box-version", $USER_CONFIG[:box_version])

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

      vm_cfg.vm.provision "shell", name: "Hosts", path: provision_path("hosts")
      vm_cfg.vm.provision "shell", name: "Certificate Authorities", path: provision_path("ca-certificates")
      if $USER_CONFIG[:private_registry] == "true"
        vm_cfg.vm.provision "shell", name: "Private Docker Registry", path: provision_path("insecure-registry")
      end
      if cfg["type"]
        vm_cfg.vm.provision "shell", name: "DCOS #{cfg['type'].capitalize}", path: provision_path("type-#{cfg["type"]}"), env: $PROVISION_ENV
      end
    end
  end
end
