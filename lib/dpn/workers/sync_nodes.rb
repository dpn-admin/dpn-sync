module DPN
  module Workers
    ##
    # Fetch the latest data from a remote node
    class SyncNodes < Sync

      SYNC_NAME = 'sync_nodes'.freeze

      def sync
        remote_node.update
        response = local_client.update_node(remote_node.to_hash)
        raise response.body unless response.success?
        logger.info "Updated #{remote_node.namespace} node"
        last_success_update
      rescue => e
        logger.error(e.message)
      end
    end
  end
end
