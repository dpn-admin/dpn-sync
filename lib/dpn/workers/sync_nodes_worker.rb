module DPN
  module Workers
    ##
    # Fetch the latest data from each known remote node
    class SyncNodesWorker < DPN::Workers::SyncWorker
      def perform
        nodes = DPN::Workers.nodes
        nodes.sync :nodes
      end
    end
  end
end
