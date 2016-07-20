module DPN
  module Workers
    ##
    # DPN worker to sync content
    class SyncWorker
      include Sidekiq::Worker
      sidekiq_options backtrace: 10

      def perform(content)
        nodes = DPN::Workers.nodes
        nodes.sync content
      rescue StandardError => err
        logger.error err.inspect
        false
      end
    end
  end
end
