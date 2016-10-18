module DPN
  module Workers
    ##
    # Save a fixity to a local node
    class SyncFixity < SyncContent

      private

        # Custom alias for content
        # @return [Object] fixity
        alias fixity content

        # @return [String] fixity ID
        def content_id
          fixity[:fixity_check_id]
        end

        # @return [Boolean]
        def create
          response = node_client.create_fixity_check(fixity)
          log_result('create', response)
          response.success?
        end

        # Fixity is read-only; allow `update` to be always true to skip it.
        # @return [Boolean]
        def update
          true
        end
    end
  end
end
