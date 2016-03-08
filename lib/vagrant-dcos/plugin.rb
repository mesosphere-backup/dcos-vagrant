# -*- mode: ruby -*-
# vi: set ft=ruby :

module VagrantPlugins
  module DCOS
    VERSION = '0.1'

    class Plugin < Vagrant.plugin(2)
      name "dcos"

      config :dcos_install, :provisioner do
        require_relative 'provisioner_config'
        ProvisionerConfig
      end

      provisioner :dcos_install do
        require_relative 'provisioner'
        Provisioner
      end

      provisioner :dcos_ssh do
        require_relative 'ssh_provisioner'
        SSHProvisioner
      end
    end

  end
end
