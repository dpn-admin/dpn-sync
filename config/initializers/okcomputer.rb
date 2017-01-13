require 'okcomputer'
require_relative 'sidekiq_monitor'

OkComputer.mount_at = '/status' # see config.ru for manual mount point
OkComputer.check_in_parallel = true

# Disable the default ActiveRecord-db check.
OkComputer::Registry.deregister 'database'

# Custom checks for DpnSync
module DPN
  # An abstract class for a DPN Monitor
  class DpnCheck < OkComputer::Check
    attr_reader :monitor

    def initialize(monitor)
      @monitor = monitor
    end

    def check
      mark_failure unless monitor.ok?
      mark_message monitor.message
    rescue StandardError => err
      mark_failure
      mark_message err.inspect
    end
  end

  # Report an application semantic version
  class AppVersionMonitor
    def message
      app_version
    end

    def ok?
      app_version =~ /\d*\.\d*\.\d*/ ? true : false
    end

    private

      def app_version
        @app_version ||= "dpn-sync: #{DPN::DpnSync::VERSION}"
      end
  end

  # Register the application semantic version with OkComputer
  checker = DpnCheck.new(AppVersionMonitor.new)
  OkComputer::Registry.register 'version', checker

  # Check a DPN node
  class DpnNodeCheck < DpnCheck
    def initialize(node)
      @monitor = DPN::Workers::NodeMonitor.new(node)
    end
  end

  # Register checks on remote nodes with OkComputer
  DPN::Workers.nodes.remote_nodes.each do |node|
    checker = DpnNodeCheck.new(node)
    check_name = "external-node-#{node.namespace}"
    OkComputer::Registry.register check_name, checker
  end

  # Check Sidekiq
  class SidekiqCheck < DpnCheck
    def initialize
      @monitor = SidekiqMonitor.new
    end
  end

  # Register checks on Sidekiq with OkComputer
  OkComputer::Registry.register 'feature-sidekiq', SidekiqCheck.new
end
