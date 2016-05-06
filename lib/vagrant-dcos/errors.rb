module VagrantPlugins
  module DCOS
    class InstallError < Vagrant::Errors::VagrantError
      def initialize(error_message)
        @error_message = error_message
        super(error_message)
      end

      def error_message; @error_message; end
    end
  end
end
