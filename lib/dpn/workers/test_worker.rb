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
        case msg
        when /fail/i
          raise "Failed to save msg: #{msg}"
        else
          DPN::Workers::TestMessages.save msg
        end
      end
    end
  end
end
