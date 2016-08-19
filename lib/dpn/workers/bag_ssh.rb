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
          if !user.empty? && File.exist?(identity_file)
            [
              'ssh',
              '-o PasswordAuthentication=no',
              '-o UserKnownHostsFile=/dev/null',
              '-o StrictHostKeyChecking=no',
              "-l #{user}",
              "-i #{identity_file}"
            ].join(' ')
          else
            ''
          end
        end
      end

      private

      attr_reader :settings
    end
  end
end
