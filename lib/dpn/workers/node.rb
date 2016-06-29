module DPN
  module Workers
    # A wrapper for redis node data
    class Node
      attr_reader :name
      attr_reader :namespace
      attr_reader :api_root
      attr_reader :auth_credential
      attr_reader :ssh_pubkey
      attr_reader :created_at
      attr_reader :updated_at
      attr_reader :replicate_from
      attr_reader :replicate_to
      attr_reader :restore_from
      attr_reader :restore_to
      attr_reader :protocols
      attr_reader :fixity_algorithms
      attr_reader :storage

      # @param [Hash] opts
      # @options opts [String] :namespace
      # @options opts [String] :api_root
      # @options opts [String] :auth_credential
      def initialize(opts)
        @namespace = opts[:namespace]
        @api_root = opts[:api_root]
        @auth_credential = opts[:auth_credential]
      end

      def alive?
        response = client.node(namespace)
        response.success?
      end

      def client
        @client ||= begin
          client = DPN::Client.client
          client.api_root = api_root
          client.auth_token = auth_credential
          client.user_agent = ['dpn-client', namespace].join('-')
          client.logger = DPN::Workers.create_logger(client.user_agent)
          client
        end
      end

      def to_hash
        hash = {}
        instance_variables.each do |var|
          key = var.to_s.delete('@')
          next if key == 'client'
          hash[key] = instance_variable_get(var)
        end
        hash.symbolize_keys
      end

      def update
        update_attributes
      end

      private

        def server_node_data
          response = client.node(namespace)
          raise response.body unless response.success?
          response.body
        end

        def update_attributes
          server_node_data.each_pair do |key, value|
            # Skip attributes that are explicitly initialized
            next if key == :api_root
            next if key == :namespace
            next if key == :auth_credential
            instance_variable_set("@#{key}", value)
          end
        end
    end
  end
end
