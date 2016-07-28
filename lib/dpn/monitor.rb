module DPN
  ##
  # DPN Node Monitor
  class Monitor

    def initialize
      @nodes = DPN::Workers.nodes
    end

    # @return [String] message
    def message
      nodes.map(&:status).join("\n") + "\n"
    end

    # Are all the DPN nodes alive?
    # @return [Boolean]
    def ok?
      nodes.all?(&:alive?)
    end

    private

      attr_reader :nodes
  end
end
