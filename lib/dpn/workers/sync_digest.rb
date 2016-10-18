module DPN
  module Workers
    ##
    # Save a digest to a local node
    class SyncDigest < SyncContent

      private

        # Custom alias for content
        # @return [Object] digest
        alias digest content

        # @return [String] digest ID
        def content_id
          # it's uniquely identifiable from the bag UUID and the algorithm
          "#{digest[:algorithm]}: #{digest[:bag]}"
        end

        # @return [Boolean]
        def create
          response = node_client.create_digest(digest)
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
