module DPN
  module Workers
    ##
    # Save a member to a local node
    class SyncMember < SyncContent

      private

        # Custom alias for content
        # @return [Object] member
        alias member content

        # @return [String] member ID
        def content_id
          member[:uuid]
        end

        # @return [Boolean]
        def create
          response = node_client.create_member(member)
          log_result('create', response)
          response.success?
        end

        # @return [Boolean]
        def update
          response = node_client.update_member(member)
          log_result('update', response)
          response.success?
        end
    end
  end
end
