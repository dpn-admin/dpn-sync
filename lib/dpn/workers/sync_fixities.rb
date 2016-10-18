module DPN
  module Workers
    ##
    # Fetch the latest fixities from a remote node
    class SyncFixities < Sync

      # @return [Boolean] success of sync operations
      def sync
        sync_fixity_checks
      end

      private

        # @return [Boolean] success of fixity sync operations
        def sync_fixity_checks
          success = []
          remote_client.fixity_checks do |response|
            success << create_or_update_fixity(response)
          end
          success.all? ? last_success_update : false
        end

        # @param [DPN::Client::Response] remote_response
        # @return [Boolean] success of fixity create or update operation
        def create_or_update_fixity(remote_response)
          json_data = remote_response.body
          if remote_response.success?
            local_fixity = DPN::Workers::SyncFixity.new(json_data, local_client, logger)
            local_fixity.create_or_update
          else
            logger.error json_data
            false
          end
        end
    end
  end
end
