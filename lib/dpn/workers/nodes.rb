module DPN
  module Workers
    # A wrapper for redis nodes
    class Nodes
      include Enumerable

      attr_reader :local_namespace

      def initialize(local_namespace)
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
        db_nodes.map do |node|
          DPN::Workers::Node.new(node.symbolize_keys)
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
      def db_nodes
        redis_nodes
      end

      private

        # @return nodes [Array<Hash>]
        def redis_nodes
          JSON.parse(REDIS.get('nodes'))
        end
    end
  end
end
