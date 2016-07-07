module DPN
  module Workers
    # A wrapper for redis node data
    # @!attribute [r] name
    #   @return [String]
    # @!attribute [r] namespace
    #   @return [String]
    # @!attribute [r] api_root
    #   @return [String]
    # @!attribute [r] auth_credential
    #   @return [String]
    # @!attribute [r] ssh_pubkey
    #   @return [String|nil]
    # @!attribute [r] created_at
    #   @return [String]
    # @!attribute [r] updated_at
    #   @return [String]
    # @!attribute [r] replicate_from
    #   @return [Array<String>]
    # @!attribute [r] replicate_to
    #   @return [Array<String>]
    # @!attribute [r] restore_from
    #   @return [Array<String>]
    # @!attribute [r] restore_to
    #   @return [Array<String>]
    # @!attribute [r] protocols
    #   @return [Array<String>]
    # @!attribute [r] fixity_algorithms
    #   @return [Array<String>]
    # @!attribute [r] storage
    #   @return [Hash]
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
      # @return [Boolean]
      def alive?
        response = client.node(namespace)
        response.success?
      end

      # A client for interactions with a DPN REST API
      # @see https://github.com/dpn-admin/DPN-REST-Wiki
      # @return [DPN::Client::Agent]
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

      # Update instance variables using data from the /node API
      # @return [Boolean]
      def update
        !update_attributes.empty?
      end

      private

        attr_reader :logger

        # Retrieve data from the /node API
        # @return [Hash]
        def server_node_data
          response = client.node(namespace)
          raise response.body unless response.success?
          response.body
        rescue StandardError => e
          logger.error e.inspect
          {}
        end

        # Update instance variables using data from the /node API
        # @return [Hash]
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
