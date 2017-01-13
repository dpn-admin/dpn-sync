# Load path and gems/bundler
$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

if $DEBUG
  log = File.new('log/rack_debug.log', 'w+')
  $stderr.reopen(log)
end

require 'bundler'
Bundler.require

# Local config
Dir.glob('config/initializers/**/*.rb').each { |r| require r }

# Load app
require 'sidekiq/web'
require 'sidekiq/cron/web'
require 'app/dpn_sync'

if $DEBUG
  # Use $DEBUG to drop into a console
  # rubocop:disable Lint/Debugger
  require 'pry'
  binding.pry
  exit!
  # rubocop:enable Lint/Debugger
end

map '/' do
  run DPN::DpnSync.new
end

map '/sidekiq' do
  run Sidekiq::Web.new
end
