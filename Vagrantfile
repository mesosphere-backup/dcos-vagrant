# -*- mode: ruby -*-
# vi: set ft=ruby :

require "yaml"


## BASE OS
##############################################

BOX_NAME = "aws-dcos"


## CLUSTER CONFIG
##############################################

def vagrant_path(path)
  if ! /^\w*:\/\//.match(path)
    path = "file:///vagrant/" + path
  end
  return path
end

DCOS_VM_CONFIG_PATH = ENV.fetch("DCOS_VM_CONFIG_PATH", "VagrantConfig.yaml")
DCOS_IP_DETECT_PATH = ENV.fetch("IP_DETECT_PATH", "etc/ip-detect")
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
  YAML::load_file("./VagrantConfig.yaml").each do |name,cfg|
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = true
    config.hostmanager.ignore_private_ip = false
    config.vm.box = cfg["box"] || BOX_NAME

    config.vm.define name do |vm_cfg|
      vm_cfg.vm.hostname = "#{name}.dcos"
      vm_cfg.vm.network "private_network", ip: cfg["ip"]
      vm_cfg.hostmanager.aliases = %Q(#{name} #{cfg["aliases"]} )

      vm_cfg.vm.provider "virtualbox" do |v|
        v.name = vm_cfg.vm.hostname
        v.cpus = cfg["cpus"] || 2
        v.memory = cfg["memory"] || 2048
        v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]

        if cfg["forwards"]
          cfg["forwards"].each do |from,to|
            vm_config.vm.forward_port from, to
          end
        end
      end

      vm_cfg.vm.provider "aws" do |aws, override|
        aws.ami = cfg["aws_ami"]
        aws.region = cfg["aws_region"]
        aws.instance_type = cfg["aws_instance_type"]
        aws.access_key_id = cfg["aws_access_key_id"] || ENV.fetch("AWS_ACCESS_KEY_ID", "")
        aws.secret_access_key = cfg["aws_access_key"] || ENV.fetch("AWS_SECRET_ACCESS_KEY", "")
        aws.keypair_name = cfg["aws_access_key"] || ENV.fetch("AWS_KEY_PAIR_NAME", "")

        override.ssh.pty = true
        override.ssh.username = "centos" || cfg["ssh_username"]
        override.ssh.private_key_path = cfg["ssh_private_key_path"] || ENV.fetch("AWS_PRIV_KEY_PATH", "")

        vm_cfg.vm.synced_folder ".", "/vagrant",
          type: "rsync",
          rsync__exclude: %w( .git build dcos_generate_config-*.sh dcos ),
          rsync__args: %w( --progress --archive --delete --compress --copy-links )
      end

      vm_cfg.vm.provision "shell", name: "Certificate Authorities", path: provision_path("ca-certificates")
      if cfg["type"]
        vm_cfg.vm.provision "shell", name: "DCOS #{cfg['type'].capitalize}", path: provision_path(cfg["type"]), env: PROVISION_ENV
      end
    end
  end

end

################# END ######################

__END__
