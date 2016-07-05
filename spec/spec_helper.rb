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
SimpleCov::Formatter::MultiFormatter.new(
  [
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ])
SimpleCov.start 'dpn-sync'

require 'bundler'
Bundler.setup
Bundler.require

ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'rspec'

require 'find'
%w(./config/initializers ./lib).each do |load_path|
  Find.find(load_path) { |f| require f if f =~ /\.rb$/ }
end

require File.expand_path '../../app/dpn_sync.rb', __FILE__

# Configure RSpec
module RSpecMixin
  include Rack::Test::Methods
  def app
    DpnSync
  end
end
RSpec.configure { |c| c.include RSpecMixin }
