##
# DPN Registry Sync
class DpnSync < Sinatra::Base
  register Sinatra::ConfigFile
  config_file 'config/config.yml'

  set public_folder: 'public', static: true

  # get '/' do
  #   erb :welcome
  # end
  get '/' do
    stats = Sidekiq::Stats.new
    @failed = stats.failed
    @processed = stats.processed
    @messages = REDIS.lrange('dpn-messages', 0, -1)
    erb :index
  end

  post '/msg' do

    require 'pry'; binding.pry

    DPN::Workers::Base.perform_async params[:msg]
    redirect to('/')
  end
end
