require 'rsync'
require_relative 'bag_ssh'

module DPN
  module Workers
    ##
    # A Bag Rsync Transfer
    class BagRsync

      # @param [String] source location for transfer resource
      # @param [String] target location for transfer resource
      # @param [String] type of transfer ('stage' || 'store')
      def initialize(source, target, type)
        @source = source
        @target = target
        @type = type
      end

      # @return [Boolean] success of transfer
      def rsync
        Rsync.run(source, target, options) do |result|
          unless result.success?
            msg = "Failed #{type} rsync: #{result.error}, options: #{options}"
            raise msg
          end
        end
        true
      end

      private

        attr_reader :source,
                    :target,
                    :type

        def options
          case type
          when 'stage'
            stage_options
          when 'store'
            STORE_OPTIONS
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

        STORE_OPTIONS = COMMON_OPTIONS + ' --recursive'

        # @return [String] rsync options for retrieval
        def stage_options
          COMMON_OPTIONS + ' --archive' + ssh_option
        end

        # @return [String] ssh option for retrieval
        def ssh_option
          @ssh_option ||= begin
            ssh = DPN::Workers::BagSSH.new
            ssh_cmd = ssh.stage_command
            ssh_cmd.empty? ? '' : " -e '#{ssh_cmd}'"
          end
        end
    end
  end
end
