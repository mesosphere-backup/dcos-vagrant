# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

module VagrantPlugins
  module DCOS

    class GenConfConfig < Hash
      def initialize
        super
      end

      def update(other)
        other.each do |key, value|
          self[key] = value
        end
        self
      end

      def to_yaml
        ({}.update(self)).to_yaml
      end

      def master_list
        raise NoMethodError
      end

      def master_list=(value)
        raise NoMethodError
      end

      def agent_list
        raise NoMethodError
      end

      def agent_list=(value)
        raise NoMethodError
      end

      def exhibitor_zk_hosts
        raise NoMethodError
      end

      def exhibitor_zk_hosts=(value)
        raise NoMethodError
      end

      def exhibitor_zk_hosts
        raise NoMethodError
      end

      def exhibitor_zk_hosts=(value)
        raise NoMethodError
      end

      def resolvers
        raise NoMethodError
      end

      def resolvers=(value)
        raise NoMethodError
      end
    end

    class GenConfConfig_1_5 < GenConfConfig
      def initialize
        super
        self['cluster_config'] = {}
        self['cluster_config']['master_list'] = []
        self['ssh_config'] = {}
        self['ssh_config']['target_hosts'] = []
      end

      def master_list
        self['cluster_config']['master_list']
      end

      def master_list=(value)
        self['cluster_config']['master_list'] = value
      end

      def agent_list
        self['ssh_config']['target_hosts'] - master_list
      end

      def agent_list=(value)
        self['ssh_config']['target_hosts'] = value + master_list
      end

      def exhibitor_zk_hosts
        self['cluster_config']['exhibitor_zk_hosts']
      end

      def exhibitor_zk_hosts=(value)
        self['cluster_config']['exhibitor_zk_hosts'] = value
      end

      def bootstrap_url
        self['cluster_config']['bootstrap_url']
      end

      def bootstrap_url=(value)
        self['cluster_config']['bootstrap_url'] = value
      end

      def resolvers
        self['cluster_config']['resolvers']
      end

      def resolvers=(value)
        self['cluster_config']['resolvers'] = value
      end
    end

    class GenConfConfig_1_6 < GenConfConfig
      def initialize
        super
        self['master_list'] = []
        self['agent_list'] = []
      end

      def master_list
        self['master_list']
      end

      def master_list=(value)
        self['master_list'] = value
      end

      def agent_list
        self['agent_list']
      end

      def agent_list=(value)
        self['agent_list'] = value
      end

      def exhibitor_zk_hosts
        self['exhibitor_zk_hosts']
      end

      def exhibitor_zk_hosts=(value)
        self['exhibitor_zk_hosts'] = value
      end

      def bootstrap_url
        self['bootstrap_url']
      end

      def bootstrap_url=(value)
        self['bootstrap_url'] = value
      end

      def resolvers
        self['resolvers']
      end

      def resolvers=(value)
        self['resolvers'] = value
      end
    end

    class GenConfConfigLoader
      def self.load_file(config_template_path)
        config_hash = YAML::load_file(Pathname.new(config_template_path).realpath)
        if config_hash['cluster_config']
          # 1.5 config detected
          return GenConfConfig_1_5.new.update(config_hash)
        end
        # 1.6 config default
        GenConfConfig_1_6.new.update(config_hash)
      end
    end


  end
end