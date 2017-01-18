module DPN
  module Workers
    ##
    # DPN nodes monitor
    class NodeMonitor

      def initialize(node)
        @node = node
      end

      # @return [String] message
      def message
        node.status
      end

      # Is the DPN node functional?
      # @return [Boolean]
      def ok?
        node.alive?
      end

      private

        attr_reader :node
    end
  end
end
