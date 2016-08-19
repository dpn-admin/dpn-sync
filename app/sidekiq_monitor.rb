require 'forwardable'
require 'sidekiq/api'

##
# Sidekiq Queue Monitor
class SidekiqMonitor
  extend Forwardable

  def initialize
    @queue = Sidekiq::Queue.new
    @settings = SyncSettings.sidekiq
  end

  # @return [String] queue status with size and latency
  def message
    msg = ok? ? 'OK:' : 'WARNING:'
    msg += " Sidekiq Queue: SIZE: #{size}, LATENCY: #{latency}\n"
    msg
  end

  # @return [Boolean] queue has acceptable size and latency
  def ok?
    size < acceptable_queue_size && latency < acceptable_queue_latency
  end

  private

  attr_reader :queue
  def_delegators :queue, :size, :latency

  attr_reader :settings
  def_delegators :settings, :acceptable_queue_size, :acceptable_queue_latency
end
