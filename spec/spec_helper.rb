# encoding: UTF-8

require 'single_cov'
SingleCov.setup :rspec

require 'simplecov'
require 'coveralls'
Coveralls.wear!

require 'bundler'
Bundler.setup
Bundler.require

ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'rspec'

require 'fakeredis'
REDIS = Redis.new

require 'find'
%w(./config/initializers ./lib).each do |load_path|
  Find.find(load_path) { |f| require f if f =~ /\.rb$/ }
end

require File.expand_path '../../dpn_sync.rb', __FILE__

# Configure RSpec
module RSpecMixin
  include Rack::Test::Methods
  def app
    DpnSync
  end
end
RSpec.configure { |c| c.include RSpecMixin }
