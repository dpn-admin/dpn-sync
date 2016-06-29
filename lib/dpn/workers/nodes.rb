module DPN
  module Workers
    # A wrapper for redis nodes
    class Nodes
      include Enumerable

      attr_reader :nodes
      attr_reader :local_namespace

      # @param nodes [Array<Hash>]
      # @param local_namespace [String]
      def initialize(nodes, local_namespace)
        @nodes = nodes.map { |node| DPN::Workers::Node.new(node) }
        @local_namespace = local_namespace
      end

      def each
        nodes.each { |node| yield node }
      end

      # @return node [DPN::Workers::Node]
      def local_node
        node local_namespace
      end

      # @return node [DPN::Workers::Node|nil]
      def node(namespace)
        nodes.find { |node| node.namespace == namespace }
      end

      # @return node [DPN::Workers::Node|nil]
      def remote_node(namespace)
        remote_nodes.find { |node| node.namespace == namespace }
      end

      # @return remote_nodes [Array<DPN::Workers::Node>]
      def remote_nodes
        nodes.select { |node| node.namespace != local_namespace }
      end

      # Fetch registry_object data from remote nodes to update local node
      # @param registry_object [String|Symbol]
      def sync(obj)
        case obj.to_sym
        when :bags
          sync_bags
        when :nodes
          sync_nodes
        end
      end

      private

        def sync_bags
          remote_nodes.each { |node| SyncBags.new(local_node, node).sync }
        end

        def sync_nodes
          remote_nodes.each { |node| SyncNodes.new(local_node, node).sync }
        end
    end
  end
end
