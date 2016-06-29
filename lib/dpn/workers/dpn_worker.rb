module DPN
  module Workers
    ##
    # DPN worker base class
    class Base
      include Sidekiq::Worker

      DEFAULT_TIME = Time.new(2000, 1, 1, 0, 0, 0, "+00:00").utc

      def perform(msg = 'you forgot a msg!')
        REDIS.lpush('dpn-messages', msg)
      end
    end
  end
end
