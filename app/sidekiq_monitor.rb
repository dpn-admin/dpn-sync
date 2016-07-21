require 'forwardable'
require 'sidekiq/api'

##
# Sidekiq Queue Monitor
class SidekiqMonitor
  extend Forwardable

  def initialize
    @queue = Sidekiq::Queue.new
  end

  # @return [String] message
  def message
    start = now
    msg = details # calculate it now to get elapsed time
    done = (now - start).to_f * 1000 # milliseconds
    <<-MESSAGE
      Host: #{hostname}
      PID:  #{$PID}
      Timestamp: #{start}
      Elapsed Time: #{done.to_f} milliseconds

      #{msg}
    MESSAGE
  end

  # @return [Integer] HTTP status code
  def status
    ok? ? 200 : 500
  end

  def ok?
    size < acceptable_queue_size && latency < acceptable_queue_latency
  end

  private

    attr_reader :queue
    def_delegators :queue, :size, :latency

    def_delegators :Settings, :acceptable_queue_size, :acceptable_queue_latency

    def_delegator :Time, :now, :now

    # @return [String] queue status with size and latency
    def details
      msg = ok? ? 'OK:' : 'WARNING:'
      msg += " QUEUE SIZE: #{size},"
      msg += " QUEUE LATENCY: #{latency}"
      msg
    end

    # @return [String]
    def hostname
      @hostname ||= `hostname`.chomp
    end
end
