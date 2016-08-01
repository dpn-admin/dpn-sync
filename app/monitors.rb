require 'forwardable'
require_relative 'sidekiq_monitor'

##
# DPN Registry Sync Monitors
class Monitors
  extend Forwardable

  # A 'Monitor' implements a role interface that responds to :message and :ok?
  # @param [Array<Monitor>] monitors
  def initialize(monitors)
    @monitors = monitors
  end

  # @return [String] messages from all monitors
  def messages
    start = now
    msg = monitors.map(&:message).join("\n")
    [preamble(start), msg].join("\n")
  end

  # HTTP status for all monitors, 200 for all OK, 500 otherwise
  # @return [Integer] status
  def status
    monitors.all?(&:ok?) ? 200 : 500
  end

  private

    attr_reader :monitors
    def_delegator :Time, :now, :now

    # @return [String]
    def hostname
      @hostname ||= `hostname`.chomp
    end

    # @param [Time] start
    def preamble(start)
      elapsed = (now - start).to_f * 1000 # milliseconds
      <<-MESSAGE
Host: #{hostname}
PID:  #{$PID}
Timestamp: #{start.httpdate}
Elapsed Time: #{elapsed} milliseconds

MESSAGE
    end
end
