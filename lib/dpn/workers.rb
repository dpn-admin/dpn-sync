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
    # Initialize nodes from config file
    CONFIG = YAML.load_file('config/config.yml').symbolize_keys
    REDIS.set 'nodes', CONFIG[:nodes].to_json

    class << self
      extend Forwardable
      def_delegator :nodes, :local_node
      def_delegator :nodes, :remote_node
      def_delegator :nodes, :remote_nodes

      def local_namespace
        @local_namespace ||= CONFIG[:local_namespace]
      end

      def nodes
        @nodes ||= DPN::Workers::Nodes.new local_namespace
      end

      def logger(name)
        log_level = CONFIG[:log_level] || 'none'
        return nil if log_level =~ /none/i
        logger = Logger.new(File.join('log', "#{name}.log"))
        logger.level = Logger.const_get log_level.upcase
        logger
      end
    end
  end
end
