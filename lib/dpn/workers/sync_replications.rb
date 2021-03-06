module DPN
  module Workers
    ##
    # Fetch the latest bags from a remote node
    class SyncReplications < Sync

      # @return [Boolean] success of sync operations
      def sync
        return false unless replicate_remote_node?
        sync_replications
      end

      private

        # The algorithm is:
        # 1. local node issues GET bag registry data from remote node. This
        #    is the responsibility of DPN::Workers::SyncBags and it is assumed
        #    that this will run async to this process.  So it is assumed here
        #    that a query on the local node for bags owned by the remote node
        #    will return data that is eventually consistent.
        # 2. local node iterates through the bag data that belongs to remote node
        #    from (1), to GET related replication_request data from remote node.
        # 3. Some of the replication_request data from (2) may create (POST)
        #    new data to the local node and some of it may update (PUT)
        #    existing data on the local node.
        # 4. The local node only ever updates (PUT) the local copy of the
        #    replication data using data from the remote node.  If the local
        #    node acts on the replication request and needs to update the
        #    replication data, it must PUT on the remote node.  The next
        #    time this sync runs, it will then update the local copy.

        # @return [Boolean] success of replication sync operations
        def sync_replications
          success = []
          remote_node_bags.each do |bag|
            success << remote_node_bag_replications(bag)
          end
          success.all? ? last_success_update : false
        end

        # @return [Boolean] replicate from remote node
        def replicate_remote_node?
          local_node.update
          local_node.replicate_from.include? remote_node.namespace
        end

        # @param [String] bag_uuid
        # @return [Hash] has keys :bag, :from_node, :to_node
        def replication_query(bag_uuid)
          {
            bag: bag_uuid,
            from_node: remote_node.namespace,
            to_node: local_node.namespace
            # TODO: after: last_success
          }
        end

        # @return [Boolean] success of remote node replications for a bag
        def remote_node_bag_replications(bag)
          success = []
          query = replication_query(bag[:uuid])
          remote_client.replications(query) do |response|
            # the paginated response should contain only one replication
            success << handle_replication_response(response)
          end
          success.all?
        end

        # @param [DPN::Client::Response] response a replication response
        # @return [Boolean] success of replication create or update operation
        def handle_replication_response(response)
          data = response.body
          if response.success?
            save_replication(data)
          else
            logger.error data
            false
          end
        end

        # @param [Hash] replication data
        # @return [Boolean] success of replication persistence
        def save_replication(replication)
          local_replication = DPN::Workers::SyncReplication.new(replication, local_client, logger)
          local_replication.create_or_update
        end
    end
  end
end
