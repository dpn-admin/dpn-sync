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
      end

      # Test whether a node responds to a /node API request
      # @return [Boolean]
      def alive?
        response = client.node(namespace)
        response.success?
      rescue
        false
      end

      # A connection status message that depends on whether a
      # node responds to a /node API request.
      # @return [String] connection status
      def status
        if alive?
          "OK: DPN node '#{namespace}' is alive"
        else
          "WARNING: DPN node '#{namespace}' is not responding"
        end
      end

      # A client for interactions with a DPN REST API
      # @see https://github.com/dpn-admin/DPN-REST-Wiki
      # @return [DPN::Client::Agent]
      def client
        @client ||= begin
          client = DPN::Client.client(
            api_root: api_root,
            auth_token: auth_credential,
            user_agent: ['dpn-client', namespace].join('-')
          )
          client.logger = DPN::Workers.create_logger(client.user_agent)
          client
        end
      end

      # @return [Hash]
      def to_hash
        attributes.map do |var|
          key = var.to_s.delete('@').to_sym
          [key, instance_variable_get(var)]
        end.compact.to_h
      end

      # Update instance variables using data from the /node API
      # @return [Boolean]
      def update
        !update_attributes.empty?
      end

      private

        def attributes
          skip = [:@client,]
          instance_variables.select { |var| !skip.include?(var) }
        end

        # Retrieve data from the /node API
        # @return [Hash]
        def server_node_data
          response = client.node(namespace)
          response.success? ? response.body : {}
        end

        # Select additional instance variables from the /node API.
        # Skip attributes that are explicitly initialized, because all
        # of these are required to make a successful API call.
        # @return [Hash]
        def server_update_data
          skip = [:api_root, :namespace, :auth_credential]
          server_node_data.select { |key| !skip.include?(key) }
        end

        # Update instance variables using data from the /node API
        # @return [Hash]
        def update_attributes
          server_update_data.each_pair do |key, value|
            instance_variable_set("@#{key}", value)
          end
        end
    end
  end
end
