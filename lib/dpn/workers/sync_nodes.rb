module DPN
  module Workers
    ##
    # Fetch the latest data from a remote node
    class SyncNodes < Sync

      def sync
        remote_node.update
        response = local_client.update_node(remote_node.to_hash)
        raise RuntimeError, response.body unless response.success?
        logger.info "Updated #{remote_node.namespace} node"
        last_success_update
      rescue StandardError => e
        logger.error e.inspect
        false
      end

      private

        # @private
        # @!attribute [r] job_name
        #   @return [String]
        def job_name
          'sync_nodes'
        end
    end
  end
end
