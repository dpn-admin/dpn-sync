module DPN
  module Workers
    ##
    # Replicate bags
    class BagReplications
      include Sidekiq::Worker
      sidekiq_options backtrace: 10

      # @return [Boolean] success of bag transfer operations
      def perform
        bag_transfers
      end

      private

        # @return [Boolean] success of bag replications
        def bag_transfers
          replications.all? do |repl|
            DPN::Workers::BagReplication.new(repl).replicate
          end
        end

        # GET local node bag replication data
        # @return [Array] bag replication data
        def replications
          @replications ||= begin
            # There are options for the replications query, but this
            # script pulls everything that is available to filter it here.
            replications = []
            local_client.replications(replications_query) do |response|
              replications << response.body if response.success?
            end
            replications.flatten
          end
        end

        # A replications query to find all the outstanding bag replications
        # for the local node.  The replication requests must include attributes
        # for store_requested (true), stored (false), cancelled (false).
        # @return [Hash]
        def replications_query
          # To see the options available, use pry and run
          # show-doc local_client.replications
          # [String] to_node - Namespace of the to_node of the bag.
          # [Boolean] store_requested - Filter by the value of store_requested.
          # [Boolean] stored - Filter by the value of stored.
          # [Boolean] cancelled - Filter by the value of cancelled.
          {
            store_requested: true,
            stored: false,
            cancelled: false,
            to_node: local_node.namespace
          }
        end

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
