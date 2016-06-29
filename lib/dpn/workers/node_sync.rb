module DPN
  module Workers
    ##
    # Fetch the latest data from each remote node
    class NodeSync < DPN::Workers::Base
      def perform
        DPN::Workers.nodes.each(&:update)
      end
    end
  end
end
