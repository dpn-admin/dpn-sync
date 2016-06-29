##
# Add .days.ago to Fixnum
class Fixnum
  SECONDS_IN_DAY = 24 * 60 * 60

  def days
    self * SECONDS_IN_DAY
  end

  def ago
    Time.now.utc - self
  end
end

module DPN
  module Workers
    # Worker job data persistence
    class JobData

      attr_reader :name
      attr_reader :data

      # @param name [String] job name (identifier)
      def initialize(name)
        @name = job_name
        @data = data_get(name)
      end

      # @param namespace [String] remote node namespace
      def last_success(namespace)
        node_data = data[namespace] ||= {}
        node_data['last_success'] ||= DEFAULT_TIME
      end

      # @param namespace [String] remote node namespace
      def last_success_update(namespace)
        node_data = data[namespace] ||= {}
        node_data['last_success'] = Time.now.utc
      end

      def save
        data_set(name, data)
      end

      private

        # Assume the registry data has been successfully
        # retrieved in the last 90 days
        DEFAULT_TIME = 90.days.ago

        def data_get(key)
          json = REDIS.get(key) || {}.to_json
          JSON.parse(json)
        end

        def data_set(key, data)
          REDIS.set key, data.to_json
        end
    end
  end
end
