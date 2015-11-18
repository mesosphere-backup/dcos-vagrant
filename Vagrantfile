# -*- mode: ruby -*-
# vi: set ft=ruby :

## BASE OS
##############################################

# non-updated OS [https://github.com/CommanderK5/packer-centos-template/releases/download/0.7.1/vagrant-centos-7.1.box]
BOX_NAME = "new-centos"

# updated/upgraded OS (faster, no-internet)
#BOX_NAME = "???"

## CLUSTER CONFIG
##############################################
IP_DETECT_SCRIPT="ip-detect"
DCOS_CONFIG_JSON="1_master-config.json"
#DCOS_CONFIG_JSON="3_master-config.json"

DCOS_GENERATE_CONFIG_PATH= ENV['DCOS_GENERATE_CONFIG_PATH'] || "file:///vagrant/dcos_generate_config.sh"

#### Commands for configuring systems for DCOS req, master and worker install
##############################################

DCOS_OS_REQUIREMENTS = <<SHELL
  groupadd nogroup
  groupadd docker
  usermod -aG docker vagrant
  echo ">>> Created groups (nogroup, docker) and adding to users (docker, vagrant)"

  yum install --assumeyes --tolerant --quiet tar xz unzip curl docker
  echo ">>> Added packages (tar, xz, unzip, curl, docker)"

  yum upgrade --assumeyes --tolerant --quiet
  echo ">>> Upgraded OS"

  systemctl enable docker
  echo ">>> Enabling docker"

  service docker start
  echo ">>> Starting docker and running (docker ps)"
  docker ps

  cp /vagrant/etc/hosts.file /etc/hosts
  echo ">>> Copying hosts file to system."

  sed -i s/SELINUX=enforcing/SELINUX=permissive/g /etc/selinux/config
  echo ">>> Disabled SELinux"

  sysctl -w net.ipv6.conf.all.disable_ipv6=1
  sysctl -w net.ipv6.conf.default.disable_ipv6=1
  echo ">>> Disabled IPV6"

SHELL

DCOS_BOOT_PROVISION = <<SHELL
  docker run -d -p 2181:2181 -p 2888:2888 -p 3888:3888 --name=dcos_int_zk jplock/zookeeper
  echo ">>> Creating docker service (jplock/zookeeper) for exhibitor bootstrap and quorum."

  docker run -d -v /var/tmp/dcos:/usr/share/nginx/html -p 80:80 nginx
  echo ">>> Creating docker service (nginx) for ease of distributing bootstrap artificats to cluster."
  docker ps

  mkdir -p ~/genconf && cd ~/genconf
  cp /vagrant/etc/#{IP_DETECT_SCRIPT} ./ip-detect
  cp /vagrant/etc/#{DCOS_CONFIG_JSON} ./config.json
  echo ">>> Copied (ip-detect, config.json) for building bootstrap image for system."

  cd ~ && curl -O #{DCOS_GENERATE_CONFIG_PATH}
  echo ">>> Downloading (dcos_generate_config.sh) for building bootstrap image for system."

  bash ~/dcos_generate_config.sh
  echo ">>> Built bootstrap artifacts under (#{ENV['PWD']}/genconf/serve)."

  cp -rp ~/genconf/serve/* /var/tmp/dcos/
  echo ">>> Copied bootstrap artifacts to nginx directory (/var/tmp/dcos)."

SHELL

DCOS_MASTER_PROVISION = <<SHELL
  mkdir -p ~/dcos && cd ~/dcos
  curl -O http://boot.dcos/dcos_install.sh
  bash dcos_install.sh master

SHELL

DCOS_WORKER_PROVISION = <<SHELL
  mkdir -p ~/dcos && cd ~/dcos
  curl -O http://boot.dcos/dcos_install.sh
  bash dcos_install.sh slave

SHELL

#### Instance config definitions
##############################################

Vagrant.configure(2) do |config|

    {
      :boot => {
          :ip       => '192.168.65.50',
          :memory   => 512,
          :provision    => DCOS_BOOT_PROVISION

      },
      :m1 => {
          :ip       => '192.168.65.90',
          :memory   => 3072,
          :provision    => DCOS_MASTER_PROVISION
      },
      :m2 => {
          :ip       => '192.168.65.95',
          :memory   => 3072,
          :provision    => DCOS_MASTER_PROVISION
       },
      :m3 => {
          :ip       => '192.168.65.101',
          :memory   => 3072,
          :provision    => DCOS_MASTER_PROVISION
      },
      :w1 => {
          :ip       => '192.168.65.111',
          :memory   => 2048,
          :provision    => DCOS_WORKER_PROVISION
      },
      :w2 => {
          :ip       => '192.168.65.121',
          :memory   => 2048,
          :provision    => DCOS_WORKER_PROVISION
      },
      :w3 => {
          :ip       => '192.168.65.131',
          :memory   => 2048,
          :provision    => DCOS_WORKER_PROVISION
      },
      :w4 => {
          :ip       => '192.168.65.141',
          :memory   => 3072,
          :provision    => DCOS_WORKER_PROVISION
      },
      :w5 => {
          :ip       => '192.168.65.151',
          :memory   => 3072,
          :provision    => DCOS_WORKER_PROVISION
      },
      :w6 => {
          :ip       => '192.168.65.161',
          :memory   => 3072,
          :provision    => DCOS_WORKER_PROVISION
      },

    }.each do |name,cfg|

        config.vm.define name do |vm_cfg|
          vm_cfg.vm.hostname = "#{name}.dcos"
          vm_cfg.vm.network "private_network", ip: cfg[:ip]
          vm_cfg.vm.box = BOX_NAME

          vm_cfg.vm.provider "virtualbox" do |v|
            v.name = vm_cfg.vm.hostname
            v.memory = cfg[:memory]
            v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
          end
        
          if cfg[:forwards]
            cfg[:forwards].each do |from,to|
              vm_config.vm.forward_port from, to
            end 
          end

          vm_cfg.vm.provision "shell", name: "Base Provision", inline: DCOS_OS_REQUIREMENTS

          if cfg[:provision]
            vm_cfg.vm.provision "shell", name: "Instance Provision", inline: cfg[:provision]
          end

      end
    
    end

end

################# END ######################

__END__
