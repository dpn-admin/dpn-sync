module DPN
  module Workers
    # Worker job data persistence
    class JobData

      attr_reader :name

      # @param name [String] job name (identifier)
      def initialize(name)
        @name = name
        @logger = DPN::Workers.create_logger(name)
      end

      # @param namespace [String] remote node namespace
      # @return timestamp [Time]
      def last_success(namespace)
        node_data = data_get("#{name}:#{namespace}")
        time = node_data['last_success'] || DEFAULT_TIME.to_s
        Time.parse(time).utc
      end

      # @param namespace [String] remote node namespace
      # @return [Boolean]
      def last_success_update(namespace)
        node_data = data_get("#{name}:#{namespace}")
        node_data['last_success'] = Time.now.utc
        data_set("#{name}:#{namespace}", node_data)
      end

      private

        attr_reader :logger

        # Assume there is no registry data before the year 2000
        DEFAULT_TIME = Time.new(2000,01,01,0,0,0,0).utc

        # @param key [String]
        # @return data [Hash]
        def data_get(key)
          json = REDIS.get(key) || {}.to_json
          JSON.parse(json)
        end

        # @param key [String]
        # @param data [Hash]
        # @return success [True|False]
        def data_set(key, data)
          REDIS.set(key, data.to_json) == 'OK'
        rescue Redis::BaseError => e
          logger.error e.inspect
          logger.error "FAILED to save #{key} => #{data.to_json}"
          false
        end
    end
  end
end
