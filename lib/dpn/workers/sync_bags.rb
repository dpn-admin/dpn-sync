module DPN
  module Workers
    ##
    # Fetch the latest data from a remote node
    class SyncBags < Sync

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

      # @return [Boolean] result
      def sync
        BAG_TYPES.each do |bag_type|
          query = bag_query(bag_type)
          remote_client.bags(query) do |response|
            raise RuntimeError, response.body unless response.success?
            create_or_update_bag(response.body)
          end
        end
        last_success_update
      rescue StandardError => e
        logger.error e.inspect
        false
      end

      private

        # @private
        # @return [Boolean] result
        def create_or_update_bag(bag)
          create_bag(bag) || update_bag(bag)
        rescue StandardError => e
          logger.error "FAILED  #{remote_node.namespace} bag: #{bag[:uuid]}"
          logger.error e.inspect
          false
        end

        # @private
        # @param [Hash] bag
        # @return [Boolean] result
        def create_bag(bag)
          response = local_client.create_bag(bag)
          bag_info = "#{remote_node.namespace} bag: #{bag[:uuid]}"
          if response.success?
            logger.info "SUCCESS create: #{bag_info}"
            true
          else
            logger.error "FAILED  create: #{bag_info}, status: #{response.status}"
            false
          end
        end

        # @private
        # @param [Hash] bag
        # @return [Boolean] result
        def update_bag(bag)
          response = local_client.update_bag(bag)
          bag_info = "#{remote_node.namespace} bag: #{bag[:uuid]}"
          if response.success?
            logger.info "SUCCESS update: #{bag_info}"
            true
          else
            logger.error "FAILED  update: #{bag_info}, status: #{response.status}"
            false
          end
        end
    end
  end
end
