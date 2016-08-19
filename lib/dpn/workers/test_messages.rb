module DPN
  module Workers
    ##
    # Test messages
    class TestMessages
      class << self
        # All test messages
        #
        # @return [Array<String>] messages
        def all
          REDIS.lrange(redis_key, 0, -1)
        end

        # Clear test messages
        #
        # @return [Boolean] success
        def clear
          REDIS.del(redis_key) == 0
        end

        # Save a test message
        #
        # @param [String] msg (defaults to: 'you forgot a msg!')
        # @return [Boolean] success
        def save(msg = 'you forgot a msg!')
          msg += " (processed at #{Time.now.httpdate})"
          persist(msg)
        end

        private

        # Persist a message
        #
        # @param [String] msg
        # @return [Boolean] success
        def persist(msg)
          REDIS.ltrim(redis_key, 0, 25) # limit the list size
          success = REDIS.lpush(redis_key, msg) > 0
          raise "Failed to persist message: #{msg}" unless success
          success
        end

        # A redis key for storing test messages
        #
        # @return [String] redis_key
        def redis_key
          SyncSettings.sidekiq.test_message_store
        end
      end
    end
  end
end
