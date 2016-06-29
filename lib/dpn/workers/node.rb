module DPN
  module Workers
    # A wrapper for redis node data
    class Node
      attr_reader :namespace
      attr_reader :api_root
      attr_reader :auth_credential

      # @param [Hash] opts
      # @options opts [String] :namespace
      # @options opts [String] :api_root
      # @options opts [String] :auth_credential
      def initialize(opts)
        @namespace = opts[:namespace]
        @api_root = opts[:api_root]
        @auth_credential = opts[:auth_credential]
      end

      def client
        @client ||= begin
          client = DPN::Client.client
          client.api_root = api_root
          client.auth_token = auth_credential
          client.user_agent = ['dpn-client', namespace].join('-')
          client.logger = DPN::Workers.logger(client.user_agent)
          client
        end
      end

      def update
        response = client.node(namespace)
        raise response.body unless response.success?
        # update the attributes of this node using the API response, e.g.
        # => {:name=>"sdr",
        # :namespace=>"sdr",
        # :api_root=>"http://192.168.33.11",
        # :ssh_pubkey=>nil,
        # :created_at=>"2016-06-08T22:00:34Z",
        # :updated_at=>"2016-06-08T22:00:34Z",
        # :replicate_from=>["hathi", "tdr", "chron", "aptrust"],
        # :replicate_to=>["hathi", "tdr", "chron", "aptrust"],
        # :restore_from=>["hathi", "tdr", "chron", "aptrust"],
        # :restore_to=>["hathi", "tdr", "chron", "aptrust"],
        # :protocols=>["rsync"],
        # :fixity_algorithms=>["sha256", "md5"],
        # :storage=>{:region=>"default", :type=>"default"}}

        # TODO: check the details of the response data

        require 'pry'; binding.pry

        node_data = response.body
        @api_root = node_data[:api_root]
        @auth_credential = node_data[:auth_credential]
      end

      def to_json
      end
    end
  end
end
