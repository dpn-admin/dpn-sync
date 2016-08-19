require 'rsync'
require_relative 'bag_paths'
require_relative 'bag_ssh'

module DPN
  module Workers
    ##
    # A Bag Rsync Transfer
    class BagRsync
      # @param [String] source location for transfer resource
      # @param [String] target location for transfer resource
      # @param [String] type of transfer ('retrieve' || 'preserve')
      def initialize(source, target, type)
        @paths = DPN::Workers::BagPaths.new
        @source = source
        @target = target
        @type = type
      end

      # @return [Boolean] success of transfer
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

      PRESERVE_OPTIONS = COMMON_OPTIONS + ' --recursive'

      # @return [String] rsync options for retrieval
      def retrieve_options
        COMMON_OPTIONS + ' --archive' + ssh_option
      end

      # @return [String] ssh option for retrieval
      def ssh_option
        @ssh_option ||= begin
          ssh = DPN::Workers::BagSSH.new
          ssh_cmd = ssh.retrieve_command
          ssh_cmd.empty? ? '' : " -e #{ssh_cmd}"
        end
      end
    end
  end
end
