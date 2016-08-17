module DPN
  module Workers
    ##
    # DPN worker base class
    class TestWorker
      include Sidekiq::Worker

      # Save a test message
      #
      # @param [String] msg (defaults to: 'you forgot a msg!')
      # @return [Boolean] success
      def perform(msg = 'you forgot a msg!')
        msg += " (processed at #{Time.now.httpdate})"
        success = REDIS.lpush(redis_key, msg) > 0
        raise "Failed to save message: #{msg}" unless success
        success
      end

      private

        # A redis key for storing test messages
        # @return [String] redis_key
        def redis_key
          SyncSettings.sidekiq.test_message_store
        end
    end
  end
end
