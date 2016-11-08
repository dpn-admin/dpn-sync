require 'forwardable'

module DPN
  module Workers
    ##
    # BagSSH manages ssh options used in DPN bag replication
    class BagSSH
      extend Forwardable

      # Public accessors for SyncSettings.ssh parameters
      def_delegators :settings, :user, :identity_file

      # Initialize accessors for SyncSettings.ssh parameters
      def initialize
        @settings = SyncSettings.ssh
      end

      # Construct an ssh command for rsync, if an ssh identity file is
      # provided in the SyncSettings.replication configuration.
      # @return [String] ssh command
      def retrieve_command
        @_retrieve_command ||= begin
          return '' if ssh_user.empty? || ssh_identity_file.empty?
          [
            'ssh',
            '-o PasswordAuthentication=no',
            '-o UserKnownHostsFile=/dev/null',
            '-o StrictHostKeyChecking=no',
            ssh_user,
            ssh_identity_file
          ].join(' ')
        end
      end

      private

        attr_reader :settings

        def ssh_user
          @_ssh_user ||= user.to_s.empty? ? '' : "-l #{user}"
        end

        def ssh_identity_file
          @_ssh_identity_file ||= identity_file.to_s.empty? ? '' : "-i #{identity_file}"
        end
    end
  end
end
