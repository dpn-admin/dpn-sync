module DPN
  module Workers
    # A wrapper for redis node data
    class Node
      # @!attribute [r] name
      #   @return [String]
      attr_reader :name
      # @!attribute [r] namespace
      #   @return [String]
      attr_reader :namespace
      # @!attribute [r] api_root
      #   @return [String]
      attr_reader :api_root
      # @!attribute [r] auth_credential
      #   @return [String]
      attr_reader :auth_credential
      # @!attribute [r] ssh_pubkey
      #   @return [String|nil]
      attr_reader :ssh_pubkey
      # @!attribute [r] created_at
      #   @return [String]
      attr_reader :created_at
      # @!attribute [r] updated_at
      #   @return [String]
      attr_reader :updated_at
      # @!attribute [r] replicate_from
      #   @return [Array<String>]
      attr_reader :replicate_from
      # @!attribute [r] replicate_to
      #   @return [Array<String>]
      attr_reader :replicate_to
      # @!attribute [r] restore_from
      #   @return [Array<String>]
      attr_reader :restore_from
      # @!attribute [r] restore_to
      #   @return [Array<String>]
      attr_reader :restore_to
      # @!attribute [r] protocols
      #   @return [Array<String>]
      attr_reader :protocols
      # @!attribute [r] fixity_algorithms
      #   @return [Array<String>]
      attr_reader :fixity_algorithms
      # @!attribute [r] storage
      #   @return [Hash]
      attr_reader :storage

      # @param [Hash] opts
      # @option opts [String] :namespace
      # @option opts [String] :api_root
      # @option opts [String] :auth_credential
      def initialize(opts)
        @namespace = opts[:namespace]
        @api_root = opts[:api_root]
        @auth_credential = opts[:auth_credential]
        @logger = DPN::Workers.create_logger(namespace)
      end

      # Test whether a node responds to a /node API request
      # @return [True|False]
      def alive?
        response = client.node(namespace)
        response.success?
      end

      # @return [DPN::Client::Agent] client
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

      # @return [Hash]
      def to_hash
        hash = {}
        instance_variables.each do |var|
          key = var.to_s.delete('@')
          next if key == 'client'
          next if key == 'logger'
          hash[key] = instance_variable_get(var)
        end
        hash.symbolize_keys
      end

      # Set instance variables using node data from the HTTP API
      # @return [True|False]
      def update
        !update_attributes.empty?
      end

      private

        # @private
        # @!attribute [r] logger
        #   @return [Logger]
        attr_reader :logger

        # Retrieve node data from the HTTP API
        # @private
        def server_node_data
          response = client.node(namespace)
          raise response.body unless response.success?
          response.body
        rescue StandardError => e
          logger.error e.inspect
          {}
        end

        # Set instance variables using node data from the HTTP API
        # @private
        # @return [Hash] attributes
        def update_attributes
          server_node_data.each_pair do |key, value|
            # Skip attributes that are explicitly initialized, because all
            # of these are required to make a successful API call.
            next if key == :api_root
            next if key == :namespace
            next if key == :auth_credential
            instance_variable_set("@#{key}", value)
          end
        end
    end
  end
end
