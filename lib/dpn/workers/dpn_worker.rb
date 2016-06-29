module DPN
  module Workers
    ##
    # DPN worker base class
    class Base
      include Sidekiq::Worker

      def perform(msg = 'you forgot a msg!')
        REDIS.lpush('dpn-messages', msg)
      end
    end
  end
end
