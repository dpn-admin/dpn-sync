module DPN
  module Workers
    ##
    # Save a replication to a node
    class SyncReplication < SyncContent
      private

        # Custom alias for content
        # @return [Object] replication
        alias replication content

        # @return [String] replication UUID
        def content_id
          replication[:replication_id]
        end

        # @return [Boolean]
        def create
          response = node_client.create_replication(replication)
          log_result('create', response)
          response.success?
        end

        # @return [Boolean]
        def update
          response = node_client.update_replication(replication)
          log_result('update', response)
          response.success?
        end
    end
  end
end
