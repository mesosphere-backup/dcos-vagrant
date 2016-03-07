# -*- mode: ruby -*-
# vi: set ft=ruby :

module VagrantPlugins
  module DCOS
    class Config < Vagrant.plugin(2, :config)
      attr_accessor :parallel
      attr_accessor :machine_types
      attr_accessor :config_template_path

      def initialize()
        super
        @parallel = UNSET_VALUE
        @machine_types = UNSET_VALUE
        @config_template_path = UNSET_VALUE
      end

      def finalize!
        # defaults after merging
        @parallel = false if @parallel == UNSET_VALUE
        @machine_types = {} if @machine_types == UNSET_VALUE
        @config_template_path = 'etc/config-1.6.yaml' if @config_template_path == UNSET_VALUE
      end

      # The validation method is given a machine object, since validation is done for each machine that Vagrant is managing
      def validate(machine)
        errors = _detected_errors

        unless [true, false].include?(@parallel)
          errors << "Field must be a boolean: config.dcos_install.parallel"
        end

        # Validate required fields
        required_fields = [
          :machine_types,
          :config_template_path,
        ]
        required_fields.each do |field_name|
          value = send(field_name.to_sym)
          if value.nil? || value.empty? || value == UNSET_VALUE
            errors << "Missing required config field: config.dcos_install.#{field_name}"
          end
        end

        return { "dcos" => errors } unless errors.empty?

        # Validate required files
        required_file_fields = [
          :config_template_path,
        ]
        required_file_fields.each do |field_name|
          file_path = send(field_name.to_sym)
          unless File.file?(file_path)
            errors << "File not found: '#{file_path}'. Ensure that the file exists or reconfigure its location (config.dcos_install.#{field_name})"
          end
        end

        { "dcos" => errors }
      end
    end
  end
end
