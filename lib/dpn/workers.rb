require_relative 'init'

module DPN
  ##
  # DPN Workers
  module Workers
    ##
    # Convenience class methods (must be thread safe)
    class << self
      ##
      # Create a new instance of DPN::Workers::Nodes using the
      # definition in Settings.nodes and Settings.local_namespace
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
