# -*- mode: ruby -*-
# vi: set ft=ruby :

module VagrantPlugins
  module DCOS
    class SSHProvisioner < Vagrant.plugin(2, :provisioner)
      def configure(root_config)
      end

      def provision
        sync_keys(@machine)
      end

      protected

      # generate a shared ssh key to use on all machines (required by dcos ssh installer)
      def sync_keys(machine)
        private_key, openssh_key = read_or_create_ssh_keys(machine.env)

        update_ssh_key(machine, private_key, openssh_key)
      end

      def read_or_create_ssh_keys(env)
        key_dir = Pathname.new("#{env.local_data_path}/dcos")
        private_key_file = key_dir + 'private_key_vagrant'
        public_key_file = key_dir + 'public_key_vagrant.pub'

        if private_key_file.file? && public_key_file.file?
          env.ui.output('    host: Found existing keys')
          private_key = private_key_file.read.strip
          openssh_key = public_key_file.read.strip
        else
          env.ui.output('    host: Generating new keys...')
          require 'vagrant/util/keypair'
          _public_key, private_key, openssh_key = Vagrant::Util::Keypair.create
          key_dir.mkpath
          private_key_file.open('w') { |io| io.write(private_key) }
          public_key_file.open('w') { |io| io.write(openssh_key) }
        end

        Vagrant::Util::SSH.check_key_permissions(private_key_file)

        [private_key, openssh_key]
      end

      # from https://github.com/mitchellh/vagrant/blob/master/plugins/communicators/ssh/communicator.rb#L159
      def update_ssh_key(machine, private_key, openssh_key)
        # If we don't have the power to insert/remove keys, then its an error
        cap = machine.guest.capability?(:insert_public_key) && machine.guest.capability?(:remove_public_key)
        raise Vagrant::Errors::SSHInsertKeyUnsupported unless cap

        machine.ui.output('Inserting generated public key within guest...')
        # Hack to fix a vagrant bug in 1.8.3 & 1.8.4
	    # https://github.com/mitchellh/vagrant/issues/7455
        if VagrantPlugins::GuestLinux::Guest.new.detect?(machine)
          linux_insert_public_key(machine, openssh_key)
		else
          machine.guest.capability(:insert_public_key, openssh_key)
        end

        # Write out the private key (.vagrant/machines/<name>/<provider>/private_key) so vagrant can find it.
        machine.ui.output('Configuring vagrant to connect using generated private key...')
        machine.data_dir.join('private_key').open('w+') do |f|
          f.write(private_key)
        end

        # Remove the old key if it exists
        machine.ui.output("Removing insecure key from the guest, if it's present...")
        vagrant_public_key = Vagrant.source_root.join('keys', 'vagrant.pub').read.chomp
        machine.guest.capability(:remove_public_key, vagrant_public_key)

        # TODO: systemctl restart sshd.service?
      end

      def linux_insert_public_key(machine, contents)
		comm = machine.communicate
		contents = contents.chomp
		contents = Vagrant::Util::ShellQuote.escape(contents, "'")

		comm.execute <<-EOH.gsub(/^ {12}/, '')
		  mkdir -p ~/.ssh
		  chmod 0700 ~/.ssh
		  [ "$(tail -n 1 ~/.ssh/authorized_keys)" != "" ] && echo >> ~/.ssh/authorized_keys
		  printf '#{contents}\\n' >> ~/.ssh/authorized_keys
		  chmod 0600 ~/.ssh/authorized_keys
		EOH
	  end
    end
  end
end
