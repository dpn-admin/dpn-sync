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
        data_key = "#{name}:#{namespace}"
        node_data = data_get(data_key)
        node_data['last_success'] = Time.now.utc
        data_set(data_key, node_data)
      end

      private

        def logger
          @logger ||= DPN::Workers.create_logger("#{name}_data")
        end

        # Assume there is no registry data before the year 2000
        DEFAULT_TIME = Time.utc(2000, 1, 1, 0, 0, 0)

        # @param [String] key
        # @return [Hash] data
        def data_get(key)
          json = REDIS.get(key) || {}.to_json
          JSON.parse(json)
        rescue Redis::BaseError => err
          logger.error "Cannot get #{key}.  ERROR: #{err.inspect}"
          {}
        end

        # @param [String] key
        # @param [Hash] data
        # @return [Boolean] success
        def data_set(key, data)
          value = data.to_json
          REDIS.set(key, value) == 'OK'
        rescue Redis::BaseError => err
          logger.error "Cannot save #{key} => #{value}.  ERROR: #{err.inspect}"
          false
        end
    end
  end
end
