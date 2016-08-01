require 'sinatra'
require 'sinatra/base'
require_relative 'monitors'

##
# DPN Registry Sync
class DpnSync < Sinatra::Base
  set :app_file, __FILE__
  set :root, File.expand_path(File.join(File.dirname(__FILE__), '..'))
  set :public_folder, proc { File.expand_path(File.join(root, 'app', 'public')) }, static: true
  set :views, proc { File.expand_path(File.join(root, 'app', 'views')) }

  register Config

  configure do
    unless ENV['RACK_ENV'] == 'test'
      enable :logging
      file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
      file.sync = true
      use Rack::CommonLogger, file
    end
  end

  get '/' do
    erb :welcome
  end

  get '/test' do
    @stats = Sidekiq::Stats.new
    @messages = REDIS.lrange(Settings.sidekiq.test_message_store, 0, -1)
    erb :test
  end

  post '/msg' do
    DPN::Workers::TestWorker.perform_async Time.now.utc.httpdate
    redirect to("test")
  end

  post '/msg/clear' do
    REDIS.del(Settings.sidekiq.test_message_store)
    redirect to("test")
  end

  get '/is_it_working' do
    content_type 'text/plain'
    cache_control :none
    monitors = Monitors.new [SidekiqMonitor.new, DPN::Monitor.new]
    status monitors.status
    body monitors.messages
  end
end
