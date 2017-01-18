require 'sinatra'
require 'sinatra/base'
require 'okcomputer'

module DPN
  ##
  # DPN Registry Sync
  class DpnSync < Sinatra::Base
    VERSION = '0.5.2'.freeze

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

    get '/status.?:format?' do
      okcomputer_headers
      begin
        checks = OkComputer::Registry.all
        checks.run
        status checks.success? ? 200 : 500
        data = case params[:format]
               when 'json'
                 checks.to_json
               else
                 checks.values.map do |check|
                   "#{check.registrant_name}:\n\t#{check.message}\n"
                 end.join("\n")
               end
        body data
      rescue StandardError => err
        status 500
        body err.inspect
      end
    end

    get '/status/:check.?:format?' do
      okcomputer_headers
      begin
        check = OkComputer::Registry.fetch(params[:check])
        check.run
        status check.success? ? 200 : 500
        case params[:format]
        when 'json'
          body check.to_json
        else
          body check.message
        end
      rescue OkComputer::Registry::CheckNotFound => err
        status 404
        body err.message
      rescue StandardError => err
        status 500
        body err.inspect
      end
    end

    helpers do
      def okcomputer_headers
        cache_control :none
        case params[:format]
        when 'json'
          content_type 'application/json'
        else
          content_type 'text/plain'
        end
      end
    end
  end
end
