require 'active_support/core_ext/numeric/time'

module DPN
  module Workers
    # Worker job data persistence
    class JobData

      attr_reader :name

      # @param name [String] job name (identifier)
      def initialize(name)
        @name = name
      end

      # @param namespace [String] remote node namespace
      # @return timestamp [Time]
      def last_success(namespace)
        node_data = data_get("#{name}:#{namespace}")
        node_data['last_success'] || DEFAULT_TIME
      end

      # @param namespace [String] remote node namespace
      def last_success_update(namespace)
        node_data = data_get("#{name}:#{namespace}")
        node_data['last_success'] = Time.now.utc
        data_set("#{name}:#{namespace}", node_data)
      end

      private

        # Assume the registry data has been successfully
        # retrieved in the last 90 days
        DEFAULT_TIME = 90.days.ago.utc

        # @param key [String]
        # @return data [Hash]
        def data_get(key)
          json = REDIS.get(key) || {}.to_json
          JSON.parse(json)
        end

        # @param key [String]
        # @param data [Hash]
        # @raises RuntimeError
        def data_set(key, data)
          result = REDIS.set(key, data.to_json)
          raise 'Failed to save job data' unless result == 'OK'
        end
    end
  end
end
