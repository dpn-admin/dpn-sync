module DPN
  module Workers
    ##
    # Fetch the latest data from a remote node
    class Sync

      SYNC_NAME = 'sync'.freeze

      attr_reader :local_node
      attr_reader :remote_node
      attr_reader :logger

      def initialize(local_node, remote_node)
        @local_node = local_node
        @remote_node = remote_node
        @logger = DPN::Workers.create_logger(SYNC_NAME)
      end

      def sync
        # TODO: implement in subclasses
      end

      private

        def job_data
          @job_data ||= JobData.new(SYNC_NAME)
        end

        def last_success
          job_data.last_success(remote_node.namespace)
        end

        def last_success_update
          job_data.last_success_update(remote_node.namespace)
        end

        def local_client
          @local_client ||= local_node.client
        end

        def remote_client
          @remote_client ||= remote_node.client
        end
    end
  end
end
