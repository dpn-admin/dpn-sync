module DPN
  module Workers
    ##
    # Fetch the latest data from a remote node
    class SyncNodes < Sync

      def sync
        remote_node.update
        response = local_client.update_node(remote_node.to_hash)
        raise response.body unless response.success?
        logger.info "Updated #{remote_node.namespace} node"
        last_success_update
      rescue StandardError => err
        logger.error err.inspect
        false
      end
    end
  end
end
