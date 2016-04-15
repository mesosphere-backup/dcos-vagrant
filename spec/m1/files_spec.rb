require 'spec_helper'
set :os, :family => 'redhat', :release => '7', :arch => 'x86_64'

directories = [
  '/opt/mesosphere',
  '/opt/genconf'
]

files = [
  '/opt/genconf/config.yaml',
  '/opt/mesosphere/role'
]

directories.each do |d|
  describe file(d) do 
    it { should be_directory }
  end
end

files.each do |f|
  describe file(f) do
    it { should be_file}
  end
end
