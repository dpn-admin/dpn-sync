module DPN
  module Workers
    ##
    # Fetch the latest bags from a remote node
    class SyncMembers < Sync

      # @return [Boolean] success of sync operations
      def sync
        sync_members
      end

      private

        # @return [Boolean] success of member sync operations
        def sync_members
          success = []
          remote_client.members do |response|
            success << create_or_update_member(response)
          end
          success.all? ? last_success_update : false
        end

        # @param [DPN::Client::Response] remote_response
        # @return [Boolean] success of member create or update operation
        def create_or_update_member(remote_response)
          json_data = remote_response.body
          if remote_response.success?
            local_member = DPN::Workers::SyncMember.new(json_data, local_client, logger)
            local_member.create_or_update
          else
            logger.error json_data
            false
          end
        end
    end
  end
end
