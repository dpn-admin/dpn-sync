module DPN
  module Workers
    ##
    # Fetch the latest data from a remote node
    class SyncNodes < Sync

      def sync
        remote_node.update
        save_remote_node
      rescue StandardError => err
        logger.error err.inspect
        false
      end

      private

        # @return [Boolean] success of saving node information
        def save_remote_node
          response = local_client.update_node(remote_node.to_hash)
          raise response.body unless response.success?
          logger.info "Updated #{remote_node.namespace} node"
          last_success_update
        end
    end
  end
end
