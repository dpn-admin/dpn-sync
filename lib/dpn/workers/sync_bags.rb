module DPN
  module Workers
    ##
    # Fetch the latest bags from a remote node
    class SyncBags < Sync

      # @return [Boolean] success of sync operations
      def sync
        sync_bags
      rescue StandardError => err
        logger.error err.inspect
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
          success = BAG_TYPES.any? do |bag_type|
            sync_bag_type(bag_type)
          end
          success ? last_success_update : false
        end

        # @param [String] DPN bag type (I, R, or D)
        # @return [Boolean] success of bag sync operation
        def sync_bag_type(bag_type)
          result = false
          query = bag_query(bag_type)
          remote_client.bags(query) do |response|
            result = create_or_update_bag(response)
          end
          result
        end

        # @param [DPN::Client::Response]
        # @return [Boolean] success of bag create or update operation
        def create_or_update_bag(remote_response)
          bag_data = remote_response.body
          if remote_response.success?
            local_bag = DPN::Workers::SyncBag.new(bag_data, local_client, logger)
            local_bag.create_or_update
          else
            logger.error bag_data
            false
          end
        end
    end
  end
end
