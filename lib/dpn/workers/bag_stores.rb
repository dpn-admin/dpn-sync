module DPN
  module Workers
    ##
    # Replicate bags to storage path
    class BagStores < BagReplications

      protected

        # @return [Boolean] success
        def bag_transfers
          replications.all? do |repl|
            DPN::Workers::BagStore.new(repl).transfer
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
    end
  end
end
