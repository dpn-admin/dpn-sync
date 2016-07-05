module DPN
  module Workers
    ##
    # DPN worker to sync content
    class SyncWorker
      include Sidekiq::Worker

      def perform(content)
        nodes = DPN::Workers.nodes
        nodes.sync content
      rescue StandardError => e
        logger.error e.inspect
        false
      end
    end
  end
end
