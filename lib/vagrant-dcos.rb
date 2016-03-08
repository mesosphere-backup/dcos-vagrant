require_relative 'vagrant-dcos/plugin'

module VagrantPlugins
  module DCOS
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path('../../', __FILE__))
    end
  end
end