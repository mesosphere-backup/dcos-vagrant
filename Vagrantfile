# -*- mode: ruby -*-
# vi: set ft=ruby :

require "yaml"


## BASE OS
##############################################

BOX_NAME = "karlkfi/dcos-centos-virtualbox"


## CLUSTER CONFIG
##############################################

def vagrant_path(path)
  if ! /^\w*:\/\//.match(path)
    path = "file:///vagrant/" + path
  end
  return path
end

PROVISION_ENV = {
  "DCOS_IP_DETECT_PATH" => vagrant_path(ENV.fetch("IP_DETECT_PATH", "etc/ip-detect")),
  "DCOS_CONFIG_PATH" => vagrant_path(ENV.fetch("DCOS_CONFIG_PATH", "etc/1_master-config.json")),
  "DCOS_GENERATE_CONFIG_PATH" => vagrant_path(ENV.fetch("DCOS_GENERATE_CONFIG_PATH", "dcos_generate_config.sh")),
  "DCOS_JAVA_ENABLED" => ENV.fetch("DCOS_JAVA_ENABLED", "false"),
}

def provision_path(type)
  return "./provision/bin/#{type}.sh"
end


#### Setup & Provisioning
##############################################

Vagrant.configure(2) do |config|
  YAML::load_file("./VagrantConfig.yaml").each do |name,cfg|
    config.vm.define name do |vm_cfg|
      vm_cfg.vm.hostname = "#{name}.dcos"
      vm_cfg.vm.network "private_network", ip: cfg["ip"]
      vm_cfg.vm.box = cfg["box"] || BOX_NAME

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

      vm_cfg.vm.provision "shell", name: "Hosts Provision", path: provision_path("hosts")

      if ENV.fetch("DCOS_BOOT_NODE_DOCKER_REGISTRY", false)
        vm_cfg.vm.provision "shell", name: "Hosts Provision", path: provision_path("insecure-registry")
      end

      if cfg["type"]
        vm_cfg.vm.provision "shell", name: "#{cfg['type'].capitalize} Provision", path: provision_path(cfg["type"]), env: PROVISION_ENV
      end
    end
  end
end

################# END ######################

__END__
