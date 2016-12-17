module DPN
  ##
  # Simple fixture data for common specs
  module Fixtures
    extend RSpec::SharedContext

    # This logger replaces most logging files with /dev/null
    let(:null_logger) { Logger.new(File::NULL) }
  end
end
