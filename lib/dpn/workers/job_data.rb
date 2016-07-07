module DPN
  module Workers
    # Worker data persistence
    # @!attribute [r] name
    #   @return [String] the name of the worker or job
    class JobData

      attr_reader :name

      # @param [String] name job name (identifier)
      def initialize(name)
        @name = name
        @logger = DPN::Workers.create_logger(name)
      end

      # @param [String] namespace remote node namespace
      # @return [Time] timestamp of last successful sync
      def last_success(namespace)
        node_data = data_get("#{name}:#{namespace}")
        time = node_data['last_success'] || DEFAULT_TIME.to_s
        Time.parse(time).utc
      end

      # @param namespace [String] remote node namespace
      # @return [Boolean] success of the update
      def last_success_update(namespace)
        node_data = data_get("#{name}:#{namespace}")
        node_data['last_success'] = Time.now.utc
        data_set("#{name}:#{namespace}", node_data)
      end

      private

        attr_reader :logger

        # Assume there is no registry data before the year 2000
        DEFAULT_TIME = Time.utc(2000, 01, 01, 0, 0, 0)

        # @param [String] key
        # @return [Hash] data
        def data_get(key)
          json = REDIS.get(key) || {}.to_json
          JSON.parse(json)
        end

        # @param [String] key
        # @param [Hash] data
        # @return [Boolean] success
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
