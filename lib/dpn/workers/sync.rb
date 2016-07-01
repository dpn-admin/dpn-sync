module DPN
  module Workers
    ##
    # Fetch the latest data from a remote node
    class Sync

      SYNC_NAME = 'sync'.freeze

      attr_reader :local_node
      attr_reader :local_client
      attr_reader :remote_node
      attr_reader :remote_client

      def initialize(local_node, remote_node)
        @local_node = local_node
        @local_client = local_node.client
        @remote_node = remote_node
        @remote_client = remote_node.client
        @job_data = JobData.new(SYNC_NAME)
        @logger = DPN::Workers.create_logger(SYNC_NAME)
      end

      def sync
        # TODO: implement in subclasses
      end

      private

        attr_reader :job_data
        attr_reader :logger

        def last_success
          job_data.last_success(remote_node.namespace)
        end

        def last_success_update
          job_data.last_success_update(remote_node.namespace)
        end
    end
  end
end
