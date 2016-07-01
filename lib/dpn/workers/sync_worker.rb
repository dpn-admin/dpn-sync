module DPN
  module Workers
    ##
    # DPN worker to sync content
    class SyncWorker
      include Sidekiq::Worker

      def perform(content)
        nodes = DPN::Workers.nodes
        nodes.sync content
      end
    end
  end
end
