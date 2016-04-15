require 'spec_helper'
set :os, :family => 'redhat', :release => '7', :arch => 'x86_64'

describe selinux do 
  it { should be_permissive }
end
