module VagrantPlugins
  module DCOS
    class AddressResolutionError < Vagrant::Errors::VagrantError
      def initialize(machine_name)
        super("Failed to find IP address of machine: #{machine_name}")
      end
    end
  end
end
