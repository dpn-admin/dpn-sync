module DPN
  module Workers
    ##
    # Fetch the latest digests from a remote node
    class SyncDigests < Sync

      # @return [Boolean] success of sync operations
      def sync
        sync_digests
      end

      private

        # @return [Boolean] success of digest sync operations
        def sync_digests
          success = []
          remote_client.digests do |response|
            success << create_or_update_digest(response)
          end
          success.all? ? last_success_update : false
        end

        # @param [DPN::Client::Response] remote_response
        # @return [Boolean] success of digest create or update operation
        def create_or_update_digest(remote_response)
          json_data = remote_response.body
          if remote_response.success?
            local_digest = DPN::Workers::SyncDigest.new(json_data, local_client, logger)
            local_digest.create_or_update
          else
            logger.error json_data
            false
          end
        end
    end
  end
end
