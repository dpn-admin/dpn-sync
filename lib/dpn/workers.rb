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
      # @return [DPN::Workers::Nodes] nodes
      def nodes
        DPN::Workers::Nodes.new Settings.nodes.map(&:to_hash),
                                Settings.local_namespace
      end

      # Create a log file with monthly rotation
      # @param [String] name
      # @return [Logger] logger logs to "log/<name>.log"
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
