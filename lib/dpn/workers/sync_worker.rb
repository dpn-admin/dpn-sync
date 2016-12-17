module DPN
  module Workers
    ##
    # DPN worker to sync content
    class SyncWorker
      include Sidekiq::Worker
      sidekiq_options backtrace: 10, retry: 5

      # The current retry count is yielded. The return value of the block must
      # be an integer. It is used as the delay, in seconds.
      sidekiq_retry_in { |count| 10 * 60 * (count + 1) } # 10 minutes

      # @param [String] class_name for a class to perform a sync process
      # @return [Boolean]
      def perform(class_name)
        DPN::Workers.nodes.sync class_name
      end
    end
  end
end
