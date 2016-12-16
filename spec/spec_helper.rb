# encoding: UTF-8

require 'single_cov'
SingleCov.setup :rspec

require 'simplecov'
require 'codacy-coverage'
SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    Codacy::Formatter
  ]
)
SimpleCov.start do
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

ENV['RACK_ENV'] = 'test'
require 'bundler'
Bundler.require
require 'pry'
require 'rack/test'
require 'fakeredis'
require 'fakeredis/rspec'

# Local config
Dir.glob('./config/initializers/**/*.rb').each { |r| require r }

# Load libraries; see lib/dpn/init.rb
require_relative '../lib/dpn/workers'

# Load app
Dir.glob('./app/**/*.rb').each { |r| require r }

# Configure RSpec
module RSpecMixin
  include Rack::Test::Methods
  def app
    DpnSync
  end
end

require_relative 'fixtures/fixtures'

RSpec.configure do |config|
  config.include RSpecMixin
  config.include DPN::Fixtures

  config.before(:each) do
    allow(Logger).to receive(:new).and_return(null_logger)
    allow(Sidekiq).to receive(:logger).and_return(null_logger)
  end

  config.after(:suite) do
    cleanup_path SyncSettings.replication.staging_dir
    cleanup_path SyncSettings.replication.storage_dir
  end
end

require 'vcr'
VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.default_cassette_options = {
    record: :new_episodes, # :once is default
  }
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = false
  c.ignore_hosts 'api.codacy.com'
end

def cleanup_path(dir)
  path = File.join(dir, '*')
  FileUtils.rm_rf(Dir.glob(path))
end

# Nodes are defined in SyncSettings.nodes
# @see config/settings.yml, config/settings/test.yml
def nodes
  @nodes ||= DPN::Workers.nodes
end

def local_node
  nodes.local_node
end

def remote_node
  @remote_node ||= nodes.remote_nodes.first
end

# This example_node is used for specs where a node should fail to respond
def example_node
  @example_node ||= DPN::Workers::Node.new(
    namespace: 'example',
    api_root: 'http://node.example.org',
    auth_credential: 'example_token'
  )
end

# DPN replication requests
# @see https://github.com/dpn-admin/DPN-REST-Wiki/blob/master/Replication-Transfer-Resource.md
# @see https://github.com/dpn-admin/dpn-server/blob/master/app/models/replication_transfer.rb
# @see https://wiki.duraspace.org/display/DPNC/BagIt+Specification
def replications
  @replications ||= begin
    repls = []
    query = { to_node: local_node.namespace }
    remote_node.client.replications(query) { |response| repls << response.body }
    repls
  end
end

def replication
  @replication ||= begin
    repl = replications.sample
    return replication4travis(repl) if ENV['TRAVIS']
    repl
  end
end

def replication4travis(repl)
  # Replace the replication file :link with a fixture file.
  repl[:link] = replication_local_tarfile(repl)
  repl
end

# Construct a replication file :link with a fixture file.
# @param [Hash] repl a replication transfer request
# @return [String] local_tarfile
def replication_local_tarfile(repl)
  tar_filename = File.basename repl[:link]
  local_tarfile = File.join(Dir.pwd, 'fixtures', 'testbags', tar_filename)
  expect(File.exist?(local_tarfile)).to be true
  local_tarfile
end
