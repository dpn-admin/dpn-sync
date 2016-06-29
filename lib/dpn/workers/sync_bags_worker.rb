module DPN
  module Workers
    ##
    # Fetch the latest data from each known remote node
    class SyncBagsWorker < DPN::Workers::SyncWorker
      # Sync the latest version of remote bags into the local node
      def perform
        nodes = DPN::Workers.nodes
        nodes.sync :bags
      end
    end
  end
end
