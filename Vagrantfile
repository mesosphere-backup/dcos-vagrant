# -*- mode: ruby -*-
# vi: set ft=ruby :

require "yaml"


## BASE OS
##############################################

DCOS_BOX = ENV.fetch("DCOS_BOX", "mesosphere/dcos-centos-virtualbox")
DCOS_BOX_URL = ENV.fetch("DCOS_BOX_URL", "https://downloads.mesosphere.com/dcos-vagrant/metadata.json")
DCOS_BOX_VERSION = ENV.fetch("DCOS_BOX_VERSION", nil)


## CLUSTER CONFIG
##############################################

def vagrant_path(path)
  if ! /^\w*:\/\//.match(path)
    path = "file:///vagrant/" + path
  end
  return path
end

DCOS_VM_CONFIG_PATH = ENV.fetch("DCOS_VM_CONFIG_PATH", "VagrantConfig.yaml")
DCOS_IP_DETECT_PATH = ENV.fetch("IP_DETECT_PATH", "etc/ip-detect.sh")
DCOS_CONFIG_PATH = ENV.fetch("DCOS_CONFIG_PATH", "etc/1_master-config.json")
DCOS_GENERATE_CONFIG_PATH = ENV.fetch("DCOS_GENERATE_CONFIG_PATH", "dcos_generate_config.sh")
DCOS_JAVA_ENABLED = ENV.fetch("DCOS_JAVA_ENABLED", "false")

PROVISION_ENV = {
  "DCOS_IP_DETECT_PATH" => vagrant_path(DCOS_IP_DETECT_PATH),
  "DCOS_CONFIG_PATH" => vagrant_path(DCOS_CONFIG_PATH),
  "DCOS_GENERATE_CONFIG_PATH" => vagrant_path(DCOS_GENERATE_CONFIG_PATH),
  "DCOS_JAVA_ENABLED" => DCOS_JAVA_ENABLED,
}

def provision_path(type)
  return "./provision/bin/#{type}.sh"
end


#### Validation
##############################################

if !File.file?(DCOS_VM_CONFIG_PATH)
  raise "vm config not found: #{DCOS_VM_CONFIG_PATH}"
end

if !File.file?(DCOS_GENERATE_CONFIG_PATH)
  raise "dcos installer not found: #{DCOS_GENERATE_CONFIG_PATH}"
end

if !File.file?(DCOS_CONFIG_PATH)
  raise "dcos config not found: #{DCOS_CONFIG_PATH}"
end

if !File.file?(DCOS_IP_DETECT_PATH)
  raise "ip-detect not found: #{DCOS_IP_DETECT_PATH}"
end


#### Setup & Provisioning
##############################################

Vagrant.configure(2) do |config|
  YAML::load_file(DCOS_VM_CONFIG_PATH).each do |name,cfg|
    config.vm.define name do |vm_cfg|
      vm_cfg.vm.hostname = "#{name}.dcos"
      vm_cfg.vm.network "private_network", ip: cfg["ip"]

      # allow explicit nil values in the cfg to override the defaults
      vm_cfg.vm.box = cfg.fetch("box", DCOS_BOX)
      vm_cfg.vm.box_url = cfg.fetch("box-url", DCOS_BOX_URL)
      vm_cfg.vm.box_version = cfg.fetch("box-version", DCOS_BOX_VERSION)

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
      if cfg["type"]
        vm_cfg.vm.provision "shell", name: "DCOS #{cfg['type'].capitalize}", path: provision_path(cfg["type"]), env: PROVISION_ENV
      end
    end
  end
end
