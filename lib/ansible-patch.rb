require Vagrant.source_root.join('plugins/provisioners/ansible/provisioner/guest.rb')

module VagrantPlugins
  module Ansible
    module Provisioner
      class Guest

        # Monkey Patch: Loop over active_machines and skip missing guests
        def generate_inventory_machines
          machines = ""

          @machine.env.active_machines.each do |active_machine|
            begin
              m = @machine.env.machine(*active_machine)
              machine_name = m.name

              @inventory_machines[machine_name] = machine_name
              if @machine.name == machine_name
                machines += "#{machine_name} ansible_connection=local\n"
              else
                machines += "#{machine_name}\n"
              end
              host_vars = get_inventory_host_vars_string(machine_name)
              machines.sub!(/\n$/, " #{host_vars}\n") if host_vars
            rescue Vagrant::Errors::MachineNotFound => e
              @logger.info("Auto-generated inventory: Skip machine '#{active_machine[0]} (#{active_machine[1]})', which is not configured for this Vagrant environment.")
            end
          end

          return machines
        end

      end
    end
  end
end
