##
# DPN Registry Sync
class DpnSync < Sinatra::Base
  set :root, File.dirname(__FILE__)
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
    DPN::Workers::Base.perform_async params[:msg]
    redirect to('/test')
  end
end
