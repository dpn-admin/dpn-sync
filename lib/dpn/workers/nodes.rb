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

      # Fetch registry content from remote nodes to update local node
      # @param [String] class_name object name to handle content sync
      # @return [Boolean]
      def sync(class_name)
        sync_data class_name.constantize
      rescue ScriptError, StandardError => err
        logger.error err.inspect + err.backtrace.inspect
        false
      end

      private

      # @return [Logger]
      def logger
        @logger ||= DPN::Workers.create_logger self.class.name.gsub('::', '_')
      end

      # Iterates on remote_nodes to sync registry data into local_node
      # @param [Class] klass object to handle content type for sync
      # @return [Boolean]
      def sync_data(klass)
        remote_nodes.map { |node| klass.new(local_node, node).sync }.any?
      end
    end
  end
end
