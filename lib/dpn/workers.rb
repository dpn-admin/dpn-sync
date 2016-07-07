require_relative 'init'

##
# @see https://github.com/dpn-admin/DPN-REST-Wiki
module DPN
  ##
  # DPN Workers
  #
  # An application for synchronizing DPN registry data from remote nodes.  This
  # project uses {https://github.com/mperham/sidekiq Sidekiq} background jobs.
  #
  # Components:
  # - the DPN nodes are defined in `config/settings.yml`
  #   - the settings are handled by {DPN::Workers}
  #   - a set of DPN nodes is loaded by {DPN::Workers.nodes}
  # - a set of DPN nodes is modeled by the {DPN::Workers::Nodes} class
  #   - it requires a `local_namespace` to identify a `local_node`
  #   - it makes an important distinction between a `local_node` and `remote_nodes`
  #   - it has methods to `sync` data from `remote_nodes` into the `local_node`
  #     - various {DPN::Workers::SyncWorker} call the `sync` method
  #     - various {DPN::Workers::Sync} implement the `sync` details
  #       - they use {DPN::Workers::JobData} for tracking success
  # - a node is modeled by the {DPN::Workers::Node} class
  #   - it requires a node namespace, API URL, and authentication token
  #   - it contains a `DPN::Client::Agent` to access a node's HTTP API
  #   - the client is from https://github.com/dpn-admin/dpn-client
  #   - the HTTP API is from https://github.com/dpn-admin/dpn-server
  module Workers
    ##
    # Convenience class methods (must be thread safe)
    class << self
      ##
      # Create a new instance of DPN::Workers::Nodes using the
      # definition in Settings.nodes and Settings.local_namespace
      # @return [DPN::Workers::Nodes]
      def nodes
        DPN::Workers::Nodes.new Settings.nodes.map(&:to_hash),
                                Settings.local_namespace
      end

      # Create a log file with monthly rotation
      # @param [String] name
      # @return [Logger] logs to "log/<name>.log"
      def create_logger(name)
        logger = Logger.new(File.join('log', "#{name}.log"), 'monthly')
        logger.level = log_level
        logger
      end

      private

        # @return [Integer] a Logger log level constant
        def log_level
          log_level = Settings.log_level || 'info'
          Logger.const_get log_level.upcase
        rescue
          Logger::INFO
        end
    end
  end
end
