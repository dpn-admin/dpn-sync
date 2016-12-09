module DPN
  module Workers
    ##
    # Replicate bags
    class BagReplications
      include Sidekiq::Worker
      sidekiq_options backtrace: 10

      # @return [Boolean] success
      def perform
        bag_transfers
      end

      protected

        # @return [Boolean] success
        def bag_transfers
          raise NotImplementedError, "This #{self.class} cannot respond to: bag_transfer"
        end

        # GET local node bag replication data
        # @return [Array] bag replication data
        def replications
          @replications ||= begin
            replications = []
            local_client.replications(replications_query) do |response|
              replications << response.body if response.success?
            end
            replications.flatten
          end
        end

        # A replications query to find all the outstanding bag replications
        # for the local node.  The replication requests must include attributes
        # for store_requested, stored & cancelled.
        # @return [Hash]
        def replications_query
          # To see the options available, use pry and run
          # show-doc local_client.replications
          # [String] to_node - Namespace of the to_node of the bag.
          # [Boolean] store_requested - Filter by the value of store_requested.
          # [Boolean] stored - Filter by the value of stored.
          # [Boolean] cancelled - Filter by the value of cancelled.
          raise NotImplementedError, "This #{self.class} cannot respond to: replications_query"
        end

        #
        # Utils
        #

        # @return [Logger]
        def logger
          @logger ||= DPN::Workers.create_logger self.class.name.gsub('::', '_')
        end

        # @return [DPN::Client::Agent] accessor for local_node.client
        def local_client
          local_node.client
        end

        # @return [DPN::Workers::Node]
        def local_node
          nodes.local_node
        end

        # @return [DPN::Workers::Nodes]
        def nodes
          @nodes ||= DPN::Workers.nodes
        end
    end
  end
end
