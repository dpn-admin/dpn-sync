require 'config'
require 'forwardable'
require 'json'
require 'logger'
require_relative 'workers/node'
require_relative 'workers/nodes'
require_relative 'workers/dpn_worker'

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
    # Initialize nodes
    nodes = DPN::Workers::Nodes.new
    nodes.redis_nodes_set Settings.nodes.map(&:to_hash)

    ##
    # Convenience class methods for accessing node data
    class << self
      extend Forwardable
      def_delegator :nodes, :local_node
      def_delegator :nodes, :remote_node
      def_delegator :nodes, :remote_nodes

      def local_namespace
        @local_namespace ||= Settings.local_namespace
      end

      def nodes
        @nodes ||= DPN::Workers::Nodes.new local_namespace
      end

      def logger(name)
        log_level = Settings.log_level || 'info'
        logger = Logger.new(File.join('log', "#{name}.log"))
        logger.level = Logger.const_get log_level.upcase
        logger
      end
    end
  end
end
