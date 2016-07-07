module DPN
  module Workers
    # A collection of DPN::Workers::Node
    # @!attribute [r] nodes
    #   @return [Array<DPN::Workers::Node>] all nodes in the collection
    # @!attribute [r] local_namespace
    #   @return [String] the namespace of the local node
    class Nodes
      include Enumerable

      attr_reader :nodes
      attr_reader :local_namespace

      # @param [Array<Hash>] nodes
      # @param [String] local_namespace
      def initialize(nodes, local_namespace)
        @nodes = nodes.map { |node| DPN::Workers::Node.new(node) }
        @local_namespace = local_namespace
      end

      # @yield [DPN::Workers::Node]
      def each
        nodes.each { |node| yield node }
      end

      # Find the local node
      # @return [DPN::Workers::Node]
      def local_node
        node local_namespace
      end

      # Find a node by it's namespace
      # @param [String] namespace
      # @return [DPN::Workers::Node|nil]
      def node(namespace)
        nodes.find { |node| node.namespace == namespace }
      end

      # Find a remote node by it's namespace
      # @param [String] namespace
      # @return [DPN::Workers::Node|nil]
      def remote_node(namespace)
        remote_nodes.find { |node| node.namespace == namespace }
      end

      # Select all the remote nodes
      # @return [Array<DPN::Workers::Node>]
      def remote_nodes
        nodes.select { |node| node.namespace != local_namespace }
      end

      # Fetch registry_content data from remote nodes to update local node
      # @param [String|Symbol] registry_content
      # @return [Boolean]
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
        def sync_bags
          remote_nodes.each { |node| SyncBags.new(local_node, node).sync }
        end

        # Iterates on remote_nodes to sync node registry data into local_node
        def sync_nodes
          remote_nodes.each { |node| SyncNodes.new(local_node, node).sync }
        end
    end
  end
end
