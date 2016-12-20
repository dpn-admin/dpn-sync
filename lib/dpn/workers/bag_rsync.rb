require 'systemu'
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
      # @raise [RuntimeError]
      def rsync
        os_execute(rsync_command)
        true
      end

      private

        attr_reader :source,
                    :target,
                    :type

        # @return [String] rsync_command
        def rsync_command
          @rsync_command ||= "rsync #{options} #{source} #{target}"
        end

        # @return [String] options for rsync
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
          ssh_option + COMMON_OPTIONS + ' --archive'
        end

        # @return [String] ssh option for retrieval
        def ssh_option
          @ssh_option ||= begin
            ssh = DPN::Workers::BagSSH.new
            ssh_cmd = ssh.stage_command
            ssh_cmd.empty? ? '' : " -e '#{ssh_cmd}'"
          end
        end

        # Executes a system command in a subprocess.
        # The method returns stdout from the command if execution succeeds.
        # The method will raise an exception if execution fails; the exception
        # message will explain the failure.
        # @param [String] command the command to be executed
        # @return [String] stdout from the command if execution was successful
        # @raise [RuntimeError]
        def os_execute(command)
          status, stdout, stderr = systemu(command)
          status.exitstatus.zero? ? stdout : raise(stderr)
        rescue
          msg = ["Command failed to execute: #{command}"]
          msg << "  STDERR: #{stderr.split($/).join('; ')}" if !stderr.empty?
          msg << "  STDOUT: #{stdout.split($/).join('; ')}" if !stdout.empty?
          raise msg.join("\n")
        end
    end
  end
end
