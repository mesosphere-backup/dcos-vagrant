# -*- mode: ruby -*-
# vi: set ft=ruby :

require "yaml"

## BASE OS
##############################################

BOX_NAME = "dcos"


## CLUSTER CONFIG
##############################################

def vagrant_path(path)
  if ! /^\w*:\/\//.match(path)
    path = "file:///vagrant/" + path
  end
  return path
end

DCOS_VM_CONFIG_PATH = ENV.fetch("DCOS_VM_CONFIG_PATH", "VagrantConfig.yaml")
DCOS_IP_DETECT_PATH = ENV.fetch("IP_DETECT_PATH", "provision/bin/ip-detect.sh")
DCOS_IP_DETECT_AWS_PATH = ENV.fetch("IP_DETECT_PATH", "provision/bin/ip-detect-aws.sh")
DCOS_CONFIG_PATH = ENV.fetch("DCOS_CONFIG_PATH", "etc/1_master-config.yaml")
DCOS_GENERATE_CONFIG_PATH = ENV.fetch("DCOS_GENERATE_CONFIG_PATH", "dcos_generate_config.sh")
DCOS_JAVA_ENABLED = ENV.fetch("DCOS_JAVA_ENABLED", "false")

$vagrant_cfg = YAML::load_file("./VagrantConfig.yaml")
PROVISION_ENV = {
  "DCOS_IP_DETECT_PATH" => vagrant_path(DCOS_IP_DETECT_PATH),
  "DCOS_CONFIG_PATH" => vagrant_path(DCOS_CONFIG_PATH),
  "DCOS_GENERATE_CONFIG_PATH" => vagrant_path(DCOS_GENERATE_CONFIG_PATH),
  "DCOS_JAVA_ENABLED" => DCOS_JAVA_ENABLED,
  "MASTER_IP" => $vagrant_cfg["m1"]["ip"]
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
  config.hostmanager.enabled = true
  config.hostmanager.manage_host = true
  config.hostmanager.ignore_private_ip = false

  $vagrant_cfg.each do |name, cfg|
    config.vm.box = cfg["box"] || BOX_NAME

  
    config.vm.define name, autostart: cfg["autostart"] || false do |vm_cfg|
      vm_cfg.vm.hostname = "#{name}.dcos"
      vm_cfg.hostmanager.aliases = %Q(#{name} #{cfg["aliases"]} )
      vm_cfg.ssh.pty = false

      if cfg["type"] == "boot"
        vm_cfg.vm.provision "ip-detect",
          type: "shell", path: DCOS_IP_DETECT_PATH, env: PROVISION_ENV, preserve_order: true

        vm_cfg.vm.provision "dcos-config",
          type: "dcos_config", template: DCOS_CONFIG_PATH, resolvers: %w( 10.0.2.3 8.8.8.8 ), preserve_order: true

        vm_cfg.vm.provision "docker" do |d|
          d.run "jplock/zookeeper", daemonize: true, restart: 'no', args: "-p 2181:2181 -p 2888:2888 -p 3888:3888"
          d.run "nginx", daemonize: true, restart: 'no', args: "-v /var/tmp/dcos:/usr/share/nginx/html -p 80:80"
        end

      end

      vm_cfg.vm.provider "virtualbox" do |v, override|
        v.name = vm_cfg.vm.hostname
        v.cpus = cfg["cpus"] || 2
        v.memory = cfg["memory"] || 2048
        v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        override.vm.network "private_network", ip: cfg["ip"]
      end

      vm_cfg.vm.provider "aws" do |aws, override|
        override.vm.box = cfg["aws_box"]

        aws.ami = cfg["aws_ami"]
        aws.security_groups = cfg["aws_security_group"] || %w( default )
        aws.region = cfg["aws_region"]
        if cfg["aws_az"]
          aws.availability_zone = cfg["aws_az"]
        end
        if cfg["aws_subnet_id"]
          aws.subnet_id = cfg["aws_subnet_id"]
        end
        aws.instance_type = cfg["aws_instance_type"]
        aws.access_key_id = cfg["aws_access_key_id"] || ENV.fetch("AWS_ACCESS_KEY_ID", "")
        aws.secret_access_key = cfg["aws_access_key"] || ENV.fetch("AWS_SECRET_ACCESS_KEY", "")
        aws.keypair_name = cfg["aws_access_key"] || ENV.fetch("AWS_KEY_PAIR_NAME", "")
        aws.tags = { "name" => "dcos" }

        override.ssh.username = "centos" || cfg["ssh_username"]
        override.ssh.private_key_path = cfg["ssh_private_key_path"] || ENV.fetch("AWS_PRIV_KEY_PATH", "")

        override.hostmanager.ip_resolver = proc do |vm, resolving_vm|
          hostname = nil
          vm.communicate.execute( %q(curl -fsSL http://169.254.169.254/latest/meta-data/public-ipv4) ) do |t, ip|
            hostname = ip
          end
          hostname.to_s
        end

        override.vm.synced_folder ".", "/vagrant",
          disabled: (cfg["type"] == "boot" ? false : true),
          type: "rsync",
          rsync_verbose: true,
          rsync__auto: false,
          rsync__exclude: %w( .git* README* etc build docs Vagrant* dcos_generate_config-*.sh dcos ),
          rsync__args: %w( --quiet --archive --size-only --compress --copy-links )

        if cfg["type"] == "boot"

          override.vm.provision "ip-detect",
            type: "shell", path: DCOS_IP_DETECT_AWS_PATH, env: PROVISION_ENV, preserve_order: true

          override.vm.provision "dcos-config",
            type: "dcos_config_aws", template: DCOS_CONFIG_PATH, resolvers: %w( 169.254.169.253 ), preserve_order: true
        end

      end

      vm_cfg.vm.provision "shell", name: "Certificate Authorities", path: provision_path("ca-certificates")
      vm_cfg.vm.provision "clean host file", type: "shell", inline: %q(sed -i "s/^127\.0\.0\.1.*localhost/127.0.0.1 localhost/" /etc/hosts)
      if cfg["type"]
        vm_cfg.vm.provision "shell", name: "DCOS #{cfg['type'].capitalize}", path: provision_path(cfg["type"]), env: PROVISION_ENV

      end

    end

  end

end

module VagrantPlugins
  module DCOS
    VERSION = '0.1'

    class ProvisionerConfig < Vagrant.plugin("2", "config")
      attr_accessor :name
      attr_accessor :template
      attr_accessor :resolvers
      attr_accessor :boot_host
      attr_accessor :master_list

      def initialize
        super
        @name = UNSET_VALUE
        @template = UNSET_VALUE
        @resolvers = UNSET_VALUE
        @boot_host = UNSET_VALUE
        @master_list = UNSET_VALUE
      end

      def finalize!
        @name = "" if @name == UNSET_VALUE
        @template = "" if @template == UNSET_VALUE
        @resolvers = [] if @resolvers == UNSET_VALUE
        @boot_host = "boot.dcos" if @boot_host == UNSET_VALUE
        @master_list = [] if @master_list == UNSET_VALUE
      end
    end

    class Provisioner < Vagrant.plugin("2", "provisioner")
      def provision
        cluster_cfg = YAML::load_file(@config.template)

        env = @machine.env
        active_machines = env.active_machines()

        cluster_cfg["cluster_config"]["bootstrap_url"] = "http://#{@config.boot_host}"
        cluster_cfg["cluster_config"]["exhibitor_zk_hosts"] = "#{@config.boot_host}:2181"
        cluster_cfg["cluster_config"]["master_list"] = []
        active_machines.each do |name, provider|
          if $vagrant_cfg[name.to_s]["type"] == 'master'
            ip = Resolv.getaddress(name.to_s)
              cluster_cfg["cluster_config"]["master_list"].push(ip)
          end
        end
        cluster_cfg["cluster_config"]["resolvers"] = @config.resolvers
        command = %Q(cat << EOF > ~/dcos/genconf/config.yaml\n#{cluster_cfg.to_yaml}\nEOF)

        @machine.communicate.sudo(command)
      end
    end

    class ProvisionerAws < Vagrant.plugin("2", "provisioner")
      def provision
        cluster_cfg = YAML::load_file(@config.template)

        env = @machine.env
        active_machines = env.active_machines()

        cluster_cfg["cluster_config"]["master_list"] = []
        active_machines.each do |name, provider|
          if $vagrant_cfg[name.to_s]["type"] == 'boot'
            machine = env.machine(name, provider)
            machine.communicate.execute( %q(curl -fsSL http://169.254.169.254/latest/meta-data/local-ipv4) ) do |t, ip|
              cluster_cfg["cluster_config"]["exhibitor_zk_hosts"] = "#{ip}:2181"
            end
          end

          if $vagrant_cfg[name.to_s]["type"] == 'master'
            machine = env.machine(name, provider)
            machine.communicate.execute( %q(curl -fsSL http://169.254.169.254/latest/meta-data/local-ipv4) ) do |t, ip|
              cluster_cfg["cluster_config"]["master_list"].push(ip)
            end
          end
        end
        cluster_cfg["cluster_config"]["resolvers"] = @config.resolvers
        command = %Q(cat << EOF > ~/dcos/genconf/config.yaml\n#{cluster_cfg.to_yaml}\nEOF)

        @machine.communicate.sudo(command)
      end
    end

    class Plugin < Vagrant.plugin("2")
      name "DCOS"

      config("dcos_config", :provisioner) do
        ProvisionerConfig
      end

      provisioner "dcos_config" do
        Provisioner
      end

      config("dcos_config_aws", :provisioner) do
        ProvisionerConfig
      end

      provisioner "dcos_config_aws" do
        ProvisionerAws
      end

    end

  end

end

################# END ######################

__END__
