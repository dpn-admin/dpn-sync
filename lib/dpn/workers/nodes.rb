module DPN
  module Workers
    # A wrapper for redis nodes
    class Nodes
      include Enumerable

      attr_reader :local_namespace

      def initialize(local_namespace = 'local')
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

      # @return nodes [Array<DPN::Workers::Node>]
      def nodes
        redis_nodes_get.map do |node|
          DPN::Workers::Node.new(node)
        end
      end

      # @return node [DPN::Workers::Node|nil]
      def remote_node(namespace)
        remote_nodes.find { |node| node.namespace == namespace }
      end

      # @return remote_nodes [Array<DPN::Workers::Node>]
      def remote_nodes
        nodes.select { |node| node.namespace != local_namespace }
      end

      # @return nodes [Array<Hash>]
      def redis_nodes_get
        REDIS.scan_each(match: 'dpn_nodes:*').collect do |node_key|
          JSON.parse(REDIS.get(node_key)).symbolize_keys
        end
      end

      # @param nodes [Array<Hash>]
      def redis_nodes_set(nodes)
        nodes.each do |node_hash|
          node = DPN::Workers::Node.new(node_hash)
          node.redis_set
        end
      end
    end
  end
end
