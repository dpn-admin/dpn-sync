module DPN
  module Workers
    ##
    # Save an ingest to a local node
    class SyncIngest < SyncContent

      private

        # Custom alias for content
        # @return [Object] ingest
        alias ingest content

        # @return [String] ingest ID
        def content_id
          ingest[:ingest_id]
        end

        # @return [Boolean]
        def create
          response = node_client.create_ingest(ingest)
          log_result('create', response)
          response.success?
        end

        # Digest is read-only; allow `update` to be always true to skip it.
        # @return [Boolean]
        def update
          true
        end
    end
  end
end
