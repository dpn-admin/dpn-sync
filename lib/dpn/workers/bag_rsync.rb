require 'rsync'

module DPN
  module Workers
    ##
    # A Bag Rsync Transfer
    class BagRsync

      # @param [Hash] replication transfer resource
      def initialize(source, target, type)
        @paths = DPN::Workers::BagPaths.new
        @source = source
        @target = target
        @type = type
      end

      # @return [Boolean] success of rsync transfer
      def rsync
        Rsync.run(source, target, options) do |result|
          raise "Failed #{type} rsync: #{result.error}" unless result.success?
        end
        true
      end

      private

        attr_reader :paths,
                    :source,
                    :target,
                    :type

        def options
          case type
          when 'preserve'
            PRESERVE_OPTIONS
          when 'retrieve'
            retrieve_options
          else
            raise "Unknown rsync type: #{type}"
          end
        end

        COMMON_OPTIONS = [
          '--copy-dirlinks',
          '--copy-unsafe-links',
          '--partial',
          '--quiet',
          '--recursive'
        ].join(' ')

        # @return [String] rsync options for preservation
        PRESERVE_OPTIONS = COMMON_OPTIONS + ' --recursive'

        # @return [String] rsync options for retrieval
        def retrieve_options
          COMMON_OPTIONS + ' --archive' + retrieve_ssh
        end

        # Construct an ssh command for rsync, if an ssh identity file is
        # provided in the SyncSettings.replication configuration.
        # @return [String] ssh command
        def retrieve_ssh
          ssh_id_file = paths.ssh_identity_file
          return '' unless File.exist? ssh_id_file
          ssh_cmd = [
            'ssh',
            '-o PasswordAuthentication=no',
            '-o UserKnownHostsFile=/dev/null',
            '-o StrictHostKeyChecking=no',
            "-i #{ssh_id_file}"
          ].join(' ')
          " -e '#{ssh_cmd}'"
        end
    end
  end
end
