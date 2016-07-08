module DPN
  module Workers
    ##
    # Save a bag to a local node
    class SyncBag

      attr_reader :bag

      def initialize(bag, local_client, logger)
        @bag = bag
        @local_client = local_client
        @logger = logger
      end

      # @return [Boolean]
      def create_or_update
        create_bag || update_bag
      rescue StandardError => e
        logger.error "FAILED  bag: #{bag_id}"
        logger.error e.inspect
        false
      end

      private

        attr_reader :local_client
        attr_reader :logger

        # @return [String] bag UUID
        def bag_id
          bag[:uuid]
        end

        # @return [Boolean]
        def create_bag
          response = local_client.create_bag(bag)
          if response.success?
            logger.info "SUCCESS create: #{bag_id}"
          else
            logger.error "FAILED  create: #{bag_id}, status: #{response.status}"
          end
          response.success?
        end

        # @return [Boolean]
        def update_bag
          response = local_client.update_bag(bag)
          if response.success?
            logger.info "SUCCESS update: #{bag_id}"
          else
            logger.error "FAILED  update: #{bag_id}, status: #{response.status}"
          end
          response.success?
        end
    end
  end
end
