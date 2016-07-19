module DPN
  module Workers
    ##
    # Save a bag to a local node
    class SyncBag < SyncContent

      private

        # Custom alias for content
        # @return [Object] bag
        alias bag content

        # @return [String] bag UUID
        def content_id
          bag[:uuid]
        end

        # @return [Boolean]
        def create
          response = node_client.create_bag(bag)
          log_result('create', response)
          response.success?
        end

        # @return [Boolean]
        def update
          response = node_client.update_bag(bag)
          log_result('update', response)
          response.success?
        end
    end
  end
end
