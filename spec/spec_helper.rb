# encoding: UTF-8

require 'single_cov'
SingleCov.setup :rspec

require 'simplecov'
require 'coveralls'

SimpleCov.profiles.define 'dpn-sync' do
  add_filter '.gems'
  add_filter '/config/environments/'
  add_filter 'pkg'
  add_filter 'spec'
  add_filter 'vendor'

  # Simplecov can detect changes using data from the
  # last rspec run.  Travis will never have a previous
  # dataset for comparison, so it can't fail a travis build.
  maximum_coverage_drop 0.1
end
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ])
SimpleCov.start 'dpn-sync'

require 'bundler'
Bundler.setup
Bundler.require

ENV['RACK_ENV'] = 'test'

require 'pry'
require 'rack/test'
require 'rspec'
require 'fakeredis'
require 'fakeredis/rspec'

# Local config
Dir.glob('./config/initializers/**/*.rb').each { |r| require r }

# Load app
Dir.glob('./lib/dpn/**/*.rb').each { |r| require r }
Dir.glob('./app/**/*.rb').each { |r| require r }

# Configure RSpec
module RSpecMixin
  include Rack::Test::Methods
  def app
    DpnSync
  end
end
RSpec.configure { |c| c.include RSpecMixin }

require 'vcr'
VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.allow_http_connections_when_no_cassette = false
  c.hook_into :webmock
  c.default_cassette_options = {
    record: :new_episodes, # :once is default
  }
  c.configure_rspec_metadata!
end

##
# Common DPN::Workers::Node instances

# This method smells of :reek:UtilityFunction
def example_node
  DPN::Workers::Node.new(
    namespace: 'example',
    api_root: 'http://node.example.org',
    auth_credential: 'example_token'
  )
end

# This method smells of :reek:UtilityFunction
def local_node
  DPN::Workers.nodes.local_node
end

# This method smells of :reek:UtilityFunction
def remote_node
  DPN::Workers.nodes.remote_nodes.first
end
