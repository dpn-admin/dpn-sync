module DPN
  module Workers
    ##
    # DPN worker base class
    class TestWorker
      include Sidekiq::Worker

      def perform(msg = 'you forgot a msg!')
        msg += " (processed at #{Time.now.utc.httpdate})"
        REDIS.lpush(Settings.sidekiq.test_message_store, msg) > 0
      rescue StandardError => err
        logger.error err.inspect
        false
      end
    end
  end
end
