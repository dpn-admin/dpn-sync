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
        nodes = DPN::Workers.nodes
        nodes.sync class_name
      rescue StandardError => err
        logger.error err.inspect
        false
      end
    end
  end
end
