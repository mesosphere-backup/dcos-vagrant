# -*- mode: ruby -*-
# vi: set ft=ruby :

module VagrantPlugins
  module DCOS
    VERSION = '0.2'.freeze

    class Plugin < Vagrant.plugin(2)
      name 'dcos'

      provisioner :dcos_ssh do
        require_relative 'ssh_provisioner'
        SSHProvisioner
      end
    end
  end
end
