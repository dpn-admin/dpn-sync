require 'spec_helper'

describe DpnSync do
  describe 'GET /' do
    it 'responds with a welcome message' do
      get '/'
      expect(last_response.body).to include 'DPN Synchronization'
    end
  end

  describe 'GET /is_it_working' do
    let(:queue) do
      queue = double(Sidekiq::Queue)
      allow(queue).to receive(:size).and_return(size)
      allow(queue).to receive(:latency).and_return(latency)
      queue
    end
    let(:size) { Settings.acceptable_queue_size - 1 }
    let(:latency) { Settings.acceptable_queue_latency - 1 }

    def check_status(status)
      expect(Sidekiq::Queue).to receive(:new).and_return(queue)
      get '/is_it_working'
      expect(last_response.status).to eq status
    end

    context 'when the Sidekiq queue' do
      it 'is acceptable - it responds with 200 status' do
        check_status 200
        expect(last_response.body).to match(/OK:/)
      end
      it 'is too large - it responds with 500 status' do
        size = Settings.acceptable_queue_size + 1
        allow(queue).to receive(:size).and_return(size)
        check_status 500
        expect(last_response.body).to match(/WARNING:/)
      end
      it 'is too slow - it responds with 500 status' do
        latency = Settings.acceptable_queue_latency + 1
        allow(queue).to receive(:latency).and_return(latency)
        check_status 500
        expect(last_response.body).to match(/WARNING:/)
      end
    end
  end

  describe 'GET /test' do
    it 'responds with a message entry form' do
      get '/test'
      expect(last_response.body).to match(/form method="post" action="\/msg"/)
    end

    it 'displays job stats' do
      stats = double(Sidekiq::Stats)
      expect(stats).to receive(:processed).and_return(5)
      expect(stats).to receive(:failed).and_return(5)
      expect(Sidekiq::Stats).to receive(:new).and_return(stats)
      get '/test'
      expect(last_response.body).to match(/Failed:.*5/)
      expect(last_response.body).to match(/Processed:.*5/)
    end

    it 'displays messages' do
      expect(REDIS).to receive(:lrange).and_return(['a', 'b'])
      get '/test'
      expect(last_response.body).to match(/<h3>Messages<\/h3>\n.*<p>a<\/p>\n.*<p>b<\/p>\n/)
    end
  end

  describe 'POST /msg' do
    let(:msg) { 'rspec test' }

    it 'initiates async message processing' do
      expect(DPN::Workers::TestWorker).to receive(:perform_async).with(msg)
      post '/msg', msg: msg
    end

    it 'redirects to the /test page' do
      post '/msg', msg: msg
      expect(last_response.status).to eq 302
      expect(last_response.location).to match(/\/test$/)
    end
  end
end
