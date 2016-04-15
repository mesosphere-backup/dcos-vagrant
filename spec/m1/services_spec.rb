require 'spec_helper'
set :os, :family => 'redhat', :release => '7', :arch => 'x86_64'

dcos_master_services = [
  'dcos-mesos-master.service',
  'dcos-exhibitor.service',
  'dcos-marathon.service',
  'dcos-nginx.service',
  'dcos-cosmos.service',
]

dcos_master_services.each do |s|
  describe service(s) do
    it { should be_running.under('systemd') }
  end
end
