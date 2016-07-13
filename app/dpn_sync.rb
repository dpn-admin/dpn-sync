require_relative 'sidekiq_monitor'

##
# DPN Registry Sync
class DpnSync < Sinatra::Base
  set :root, File.join(File.dirname(__FILE__), '..')
  register Config

  set public_folder: 'public', static: true

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
    redirect to('/test')
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
