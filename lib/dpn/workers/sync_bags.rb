module DPN
  module Workers
    ##
    # Fetch the latest data from a remote node
    class SyncBags < Sync

      SYNC_NAME = 'sync_bags'.freeze

      BAG_TYPES = %w(I R D).freeze

      def bag_query(bag_type)
        {
          bag_type: bag_type,
          admin_node: remote_node.namespace,
          after: last_success
        }
      end

      def sync
        BAG_TYPES.each do |bag_type|
          query = bag_query(bag_type)
          remote_client.bags(query) do |response|
            raise response.body unless response.success?
            create_or_update_bag(response.body)
          end
        end
        last_success_update
      rescue => e
        logger.error(e.message)
      ensure
        job_data.save
      end

      private

        def create_or_update_bag(bag)
          create_response = local_client.create_bag(bag)
          if create_response.success?
            logger.info "Created #{remote_node.namespace} bags"
          else
            update_response = local_client.update_bag(bag)
            raise update_response.body unless update_response.success?
            logger.info "Updated #{remote_node.namespace} bags"
          end
        end
    end
  end
end
