# encoding: UTF-8

require 'single_cov'
SingleCov.setup :rspec

require 'codacy-coverage'
Codacy::Reporter.start

require 'simplecov'
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
SimpleCov.start 'dpn-sync'

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
  c.ignore_hosts 'codeclimate.com'
end

def cleanup_path(dir)
  path = File.join(dir, '*')
  FileUtils.rm_rf(Dir.glob(path))
end
