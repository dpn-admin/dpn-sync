module DPN
  module Workers
    ##
    # Fetch the latest data from a remote node
    # @!attribute [r] local_node
    #   @return [DPN::Workers::Node] a local node
    # @!attribute [r] local_client
    #   @return [DPN::Client::Agent] accessor for local_node.client
    # @!attribute [r] remote_node
    #   @return [DPN::Workers::Node] a remote node
    # @!attribute [r] remote_client
    #   @return [DPN::Client::Agent] accessor for remote_node.client
    class Sync

      attr_reader :local_node
      attr_reader :local_client

      attr_reader :remote_node
      attr_reader :remote_client

      # Asynchronous updates are pulled from remote_node into local_node; the
      # remote_node must have a different namespace from local_node
      # @param local_node [DPN::Workers::Node]
      # @param remote_node [DPN::Workers::Node]
      def initialize(local_node, remote_node)
        raise ArgumentError if local_node.namespace == remote_node.namespace
        @local_node = local_node
        @local_client = local_node.client
        @remote_node = remote_node
        @remote_client = remote_node.client
      end

      # @abstract Subclass and override {#sync} to sync node content
      # @return [Boolean]
      def sync
        raise NotImplementedError, "This #{self.class} cannot respond to: sync"
      end

      private

        # @return [DPN::Workers::JobData]
        def job_data
          @job_data ||= DPN::Workers::JobData.new(job_name)
        end

        # @return [String]
        def job_name
          @job_name ||= self.class.name.gsub('::', '_')
        end

        # @return [Logger]
        def logger
          @logger ||= DPN::Workers.create_logger(job_name)
        end

        # @return [Time] last_success
        def last_success
          job_data.last_success(remote_node.namespace)
        end

        # @return [Boolean] updated
        def last_success_update
          job_data.last_success_update(remote_node.namespace)
        end
    end
  end
end
