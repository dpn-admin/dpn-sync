module DPN
  module Workers
    ##
    # DPN worker base class
    class TestWorker
      include Sidekiq::Worker

      def perform(msg = 'you forgot a msg!')
        msg += " (processed at #{Time.now.utc.httpdate})"
        REDIS.lpush(SyncSettings.sidekiq.test_message_store, msg) > 0
      end
    end
  end
end
