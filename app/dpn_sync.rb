require 'sinatra'
require 'sinatra/base'
require_relative 'monitors'

##
# DPN Registry Sync
class DpnSync < Sinatra::Base
  VERSION = '0.5.1'.freeze

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
    @messages = DPN::Workers::TestMessages.all
    erb :test
  end

  post '/msg' do
    DPN::Workers::TestWorker.perform_async Time.now.httpdate
    sleep 1 # wait for sidekiq to process the request
    redirect to("test")
  end

  post '/msg/clear' do
    DPN::Workers::TestMessages.clear
    redirect to("test")
  end

  post '/msg/fail' do
    DPN::Workers::TestWorker.perform_async 'fail for sure'
    sleep 1 # wait for sidekiq to process the request
    redirect to("test")
  end

  get '/status' do
    content_type 'text/plain'
    cache_control :none
    app_version = "DpnSync: #{VERSION}\n\n"
    begin
      monitors = Monitors.new [SidekiqMonitor.new, DPN::Monitor.new]
      details = app_version + monitors.messages
      status monitors.status
      body details
    rescue StandardError => err
      details = app_version + err.inspect
      status 500
      body details
    end
  end
end
