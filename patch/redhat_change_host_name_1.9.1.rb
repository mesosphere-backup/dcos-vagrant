# Monkey patch for network interface detection bug in Vagrant 1.9.1
# https://github.com/mitchellh/vagrant/issues/8115
#
# This file is a Derivative Work of Vagrant source, covered by the MIT license.

require Vagrant.source_root.join('plugins/guests/redhat/cap/change_host_name.rb')

module VagrantPlugins
  module GuestRedHat
    module Cap
      class ChangeHostName
        def self.change_host_name(machine, name)
          comm = machine.communicate

          if !comm.test("hostname -f | grep '^#{name}$'", sudo: false)
            basename = name.split('.', 2)[0]
            comm.sudo <<-EOH.gsub(/^ {14}/, '')
              # Update sysconfig
              sed -i 's/\\(HOSTNAME=\\).*/\\1#{name}/' /etc/sysconfig/network

              # Update DNS
              sed -i 's/\\(DHCP_HOSTNAME=\\).*/\\1\"#{basename}\"/' /etc/sysconfig/network-scripts/ifcfg-*

              # Set the hostname - use hostnamectl if available
              echo '#{name}' > /etc/hostname
              if command -v hostnamectl; then
                hostnamectl set-hostname --static '#{name}'
                hostnamectl set-hostname --transient '#{name}'
              else
                hostname -F /etc/hostname
              fi

              # Remove comments and blank lines from /etc/hosts
              sed -i'' -e 's/#.*$//' -e '/^$/d' /etc/hosts

              # Prepend ourselves to /etc/hosts
              grep -w '#{name}' /etc/hosts || {
                sed -i'' '1i 127.0.0.1\\t#{name}\\t#{basename}' /etc/hosts
              }

              # Restart network
              service network restart
            EOH
          end
        end
      end
    end
  end
end

Vagrant::UI::Colored.new.info 'Vagrant Patch Loaded: GuestRedHat change_host_name (1.9.1)'
