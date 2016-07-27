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

module GlobalLetDeclarations
  extend RSpec::SharedContext
  let(:null_logger) { Logger.new(File::NULL) }
  let(:nodes) { DPN::Workers.nodes }
  let(:local_node) { nodes.local_node }
  let(:remote_node) { nodes.remote_nodes.first }
  let(:example_node) do
    DPN::Workers::Node.new(
      namespace: 'example',
      api_root: 'http://node.example.org',
      auth_credential: 'example_token'
    )
  end
end

RSpec.configure do |config|
  config.include RSpecMixin
  config.include GlobalLetDeclarations
  config.before(:each) do
    allow(Logger).to receive(:new).and_return(null_logger)
    allow(Sidekiq).to receive(:logger).and_return(null_logger)
  end
end

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
