module DPN
  module Workers
    ##
    # DPN worker base class
    class TestWorker
      include Sidekiq::Worker

      def perform(msg = 'you forgot a msg!')
        REDIS.lpush('dpn-messages', msg) > 0
      rescue StandardError => err
        logger.error err.inspect
        false
      end
    end
  end
end
