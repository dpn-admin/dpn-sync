module DPN
  module Workers
    ##
    # Fetch the latest ingests from a remote node
    class SyncIngests < Sync

      # @return [Boolean] success of sync operations
      def sync
        sync_ingests
      end

      private

        # @return [Boolean] success of digest sync operations
        def sync_ingests
          success = []
          remote_client.ingests do |response|
            success << create_or_update_ingest(response)
          end
          success.all? ? last_success_update : false
        end

        # @param [DPN::Client::Response] remote_response
        # @return [Boolean] success of ingest create or update operation
        def create_or_update_ingest(remote_response)
          json_data = remote_response.body
          if remote_response.success?
            local_ingest = DPN::Workers::SyncIngest.new(json_data, local_client, logger)
            local_ingest.create_or_update
          else
            logger.error json_data
            false
          end
        end
    end
  end
end
