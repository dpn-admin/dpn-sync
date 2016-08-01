module DPN
  module Workers
    ##
    # DPN worker to sync content
    class SyncWorker
      include Sidekiq::Worker
      sidekiq_options backtrace: 10

      # @param [String] class_name for a class to perform a sync process
      # @return [Boolean]
      def perform(class_name)
        DPN::Workers.nodes.sync class_name
      end
    end
  end
end
