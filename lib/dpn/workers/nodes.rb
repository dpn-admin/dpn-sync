module DPN
  module Workers
    # A wrapper for redis nodes
    class Nodes
      include Enumerable

      # @!attribute [r] nodes
      #   @return [Array<DPN::Workers::Node>]
      attr_reader :nodes
      # @!attribute [r] local_namespace
      #   @return [String]
      attr_reader :local_namespace

      # @param [Array<Hash>] nodes
      # @param [String] local_namespace
      def initialize(nodes, local_namespace)
        @nodes = nodes.map { |node| DPN::Workers::Node.new(node) }
        @local_namespace = local_namespace
      end

      # @yield [DPN::Workers::Node] node
      def each
        nodes.each { |node| yield node }
      end

      # @return [DPN::Workers::Node] node
      def local_node
        node local_namespace
      end

      # @return [DPN::Workers::Node|nil] node
      def node(namespace)
        nodes.find { |node| node.namespace == namespace }
      end

      # @return [DPN::Workers::Node|nil] node
      def remote_node(namespace)
        remote_nodes.find { |node| node.namespace == namespace }
      end

      # @return [Array<DPN::Workers::Node>] remote_nodes
      def remote_nodes
        nodes.select { |node| node.namespace != local_namespace }
      end

      # Fetch registry_content data from remote nodes to update local node
      # @param [String|Symbol] registry_content
      def sync(registry_content)
        case registry_content.to_sym
        when :bags
          sync_bags
        when :nodes
          sync_nodes
        else
          return false
        end
        true
      end

      private

        # Iterates on remote_nodes to sync bag registry data into local_node
        # @private
        def sync_bags
          remote_nodes.each { |node| SyncBags.new(local_node, node).sync }
        end

        # Iterates on remote_nodes to sync node registry data into local_node
        # @private
        def sync_nodes
          remote_nodes.each { |node| SyncNodes.new(local_node, node).sync }
        end
    end
  end
end
