require_relative 'sidekiq_monitor'

##
# DPN Registry Sync
class DpnSync < Sinatra::Base
  set :app_file, __FILE__
  set :root, File.expand_path(File.join(File.dirname(__FILE__), '..'))
  set :public_folder, proc { File.expand_path(File.join(root, 'app', 'public')) }, static: true
  set :views, proc { File.expand_path(File.join(root, 'app', 'views')) }

  register Config

  get '/' do
    erb :welcome
  end

  get '/test' do
    stats = Sidekiq::Stats.new
    @failed = stats.failed
    @processed = stats.processed
    @messages = REDIS.lrange('dpn-messages', 0, -1)
    erb :test
  end

  post '/msg' do
    DPN::Workers::TestWorker.perform_async params[:msg]
    redirect to("test")
  end

  post '/msg/clear' do
    REDIS.del('dpn-messages')
    redirect to("test")
  end

  get '/is_it_working' do
    headers(
      'Content-Type': 'text/plain; charset=utf8',
      'Cache-Control': 'no-cache',
      'Date': Time.now.utc.httpdate
    )
    monitor = SidekiqMonitor.new
    status monitor.status
    body monitor.message
  end
end
