module DPN
  module Workers
    ##
    # Fetch the latest bags from a remote node
    class SyncBags < Sync

      # @return [Boolean] success of sync operations
      def sync
        sync_bags
      rescue StandardError => e
        logger.error e.inspect
        false
      end

      private

        BAG_TYPES = %w(I R D).freeze

        # @param [String] bag_type one of 'I', 'R' or 'D'
        # @return [Hash] has keys :bag_type, :admin_node, :after
        def bag_query(bag_type)
          {
            bag_type: bag_type,
            admin_node: remote_node.namespace,
            after: last_success
          }
        end

        # @return [Boolean] success of bag sync operations
        def sync_bags
          results = []
          BAG_TYPES.each do |bag_type|
            query = bag_query(bag_type)
            remote_client.bags(query) do |response|
              if response.success?
                remote_bag = response.body
                local_bag = DPN::Workers::SyncBag.new(remote_bag, local_client, logger)
                results << local_bag.create_or_update
              else
                results << false
                logger.error response.body
              end
            end
          end
          last_success_update if results.all?
          results.all?
        end
    end
  end
end
