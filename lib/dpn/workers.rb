require 'config'
require 'json'
require 'logger'
require_relative 'workers/sync'
require_relative 'workers/sync_bags'
require_relative 'workers/sync_nodes'
require_relative 'workers/node'
require_relative 'workers/nodes'
require_relative 'workers/sync_worker'
require_relative 'workers/test_worker'

module DPN
  ##
  # DPN Workers
  module Workers
    ##
    # Initialize Settings from config files
    config_files = [
      'config/settings.yml',
      "config/settings/#{ENV['RACK_ENV']}.yml",
      'config/settings.local.yml',
      "config/settings/#{ENV['RACK_ENV']}.local.yml"
    ]
    Config.load_and_set_settings(config_files)

    ##
    # Convenience class methods (must be thread safe)
    class << self
      ##
      # @return nodes [DPN::Workers::Nodes]
      def nodes
        DPN::Workers::Nodes.new Settings.nodes.map(&:to_hash),
                                Settings.local_namespace
      end

      # @param name [String]
      # @return logger [Logger] logs to "log/#{name}.log"
      def create_logger(name)
        log_level = Settings.log_level || 'info'
        logger = Logger.new(File.join('log', "#{name}.log"))
        logger.level = Logger.const_get log_level.upcase
        logger
      end
    end
  end
end
