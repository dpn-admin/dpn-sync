module DPN
  module Workers
    ##
    # @abstract Subclass and override methods for each content type
    # Save content to a node
    class SyncContent

      attr_reader :content

      def initialize(content, node_client, logger)
        @content = content
        @node_client = node_client
        @logger = logger
      end

      # @return [Boolean]
      def create_or_update
        create || update
      rescue StandardError => err
        logger.error "FAILED  : #{content_id}"
        logger.error err.inspect
        false
      end

      private

        attr_reader :node_client
        attr_reader :logger

        # @abstract Subclass and override {#content_id} for content type
        # @return [String] content ID
        def content_id
          raise NotImplementedError, "This #{self.class} cannot respond to: content_id"
          # Implementation details, e.g.:
          # bag[:uuid]
        end

        # @abstract Subclass and override {#create} for content type
        # @return [Boolean]
        def create
          raise NotImplementedError, "This #{self.class} cannot respond to: create"
          # Implementation details, e.g.:
          # response = node_client.create_bag(member)
          # log_result('create', response)
          # response.success?
        end

        # @abstract Subclass and override {#update} for content type
        # @return [Boolean]
        def update
          raise NotImplementedError, "This #{self.class} cannot respond to: update"
          # Implementation details, e.g.:
          # response = node_client.update_bag(member)
          # log_result('update', response)
          # response.success?
        end

        def log_result(operation, response)
          if response.success?
            logger.info "SUCCESS #{operation}: #{content_id}"
          else
            logger.error "FAILED  #{operation}: #{content_id}, status: #{response.status}"
          end
        end
    end
  end
end
