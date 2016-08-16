module DPN
  module Workers
    ##
    # Fetch the latest data from a remote node
    class SyncNodes < Sync

      # Sync node information from remote_node
      #
      # @return [Boolean] success
      def sync
        remote_node.update
        save_remote_node
      end

      private

        # @return [Boolean] success of saving node information
        def save_remote_node
          namespace = remote_node.namespace
          response = local_client.update_node(remote_node.to_hash)
          raise "Failed to update #{namespace} node: #{response.body}" unless response.success?
          logger.info "Updated #{namespace} node"
          last_success_update
        end
    end
  end
end
