require 'spec_helper'
set :os, :family => 'redhat', :release => '7', :arch => 'x86_64'

dcos_redhat_packages = [
  'ipset',
  'curl',
  'xz',
  'docker',
  'unzip',
]

dcos_redhat_packages.each do |p|
  describe package(p) do
    it { should be_installed }
  end
end

