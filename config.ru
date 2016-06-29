# Load path and gems/bundler
$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

if $DEBUG
  log = File.new('log/rack_debug.log', 'w')
  $stderr.reopen(log)
end

require 'bundler'
Bundler.require
require 'redis'
require 'redis-namespace'
require 'sinatra'
require 'sinatra/base'
require 'sinatra/contrib'
require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq/web'
require 'sidekiq/cron/web'

# Local config
require 'find'
%w(config/initializers lib).each do |load_path|
  Find.find(load_path) do |f|
    require f unless f =~ /\/\..+$/ || File.directory?(f)
  end
end

# Load app
require 'dpn_sync'

if $DEBUG
  # Use $DEBUG to drop into a console
  require 'pry'
  binding.pry
  exit!
end

# Run app
run Rack::URLMap.new('/' => DpnSync, '/sidekiq' => Sidekiq::Web)
