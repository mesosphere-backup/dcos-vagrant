require 'spec_helper'
set :os, :family => 'redhat', :release => '7', :arch => 'x86_64'

describe command('ls /etc/mesosphere/roles') do
  its(:stdout) { should match 'master' }
end

