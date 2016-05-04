# -*- mode: ruby -*-
# vi: set ft=ruby :

module VagrantPlugins
  module DCOS
    class ProvisionerConfig < Vagrant.plugin(2, :config)
      attr_accessor :install_method
      attr_accessor :max_install_threads
      attr_accessor :machine_types
      attr_accessor :config_template_path
      attr_accessor :postflight_timeout_seconds

      def initialize
        super
        @install_method = UNSET_VALUE
        @max_install_threads = UNSET_VALUE
        @machine_types = UNSET_VALUE
        @config_template_path = UNSET_VALUE
        @postflight_timeout_seconds = UNSET_VALUE
      end

      def finalize!
        # defaults after merging
        @install_method = :ssh_pull if @install_method == UNSET_VALUE
        @max_install_threads = 4 if @max_install_threads == UNSET_VALUE
        @machine_types = {} if @machine_types == UNSET_VALUE
        @config_template_path = 'etc/config-1.6.yaml' if @config_template_path == UNSET_VALUE
        @postflight_timeout_seconds = 900 if @postflight_timeout_seconds == UNSET_VALUE
      end

      # The validation method is given a machine object, since validation is done for each machine that Vagrant is managing
      def validate(_machine)
        errors = _detected_errors

        install_methods = [:ssh_pull, :ssh_push]
        unless install_methods.include?(@install_method.to_sym)
          errors << "Invalid config: install_method must be one of #{install_methods}"
        end

        unless @max_install_threads > 0
          errors << 'Invalid config: max_install_threads must be greater than zero'
        end

        unless @postflight_timeout_seconds > 0
          errors << 'Invalid config: postflight_timeout_seconds must be greater than zero'
        end

        # Validate required fields
        required_fields = [
          :machine_types,
          :config_template_path
        ]
        required_fields.each do |field_name|
          value = send(field_name.to_sym)
          if value.nil? || value.empty? || value == UNSET_VALUE
            errors << "Invalid config: #{field_name} is required"
          end
        end

        return { 'dcos' => errors } unless errors.empty?

        # Validate required files
        required_file_fields = [
          :config_template_path
        ]
        required_file_fields.each do |field_name|
          file_path = send(field_name.to_sym)
          unless File.file?(file_path)
            errors << "Invalid config: #{field_name} file not found: '#{file_path}' - Ensure that the file exists or reconfigure its location"
          end
        end

        { 'dcos_install' => errors }
      end
    end
  end
end
