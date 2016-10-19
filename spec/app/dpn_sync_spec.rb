require 'spec_helper'

describe DpnSync, :vcr do
  let(:settings) { SyncSettings }
  describe 'GET /' do
    it 'responds with a welcome message' do
      get '/'
      expect(last_response.body).to include 'DPN Synchronization'
    end
  end

  describe 'GET /status' do
    let(:queue) do
      queue = double(Sidekiq::Queue)
      allow(queue).to receive(:size).and_return(size)
      allow(queue).to receive(:latency).and_return(latency)
      queue
    end
    let(:size) { settings.sidekiq.acceptable_queue_size - 1 }
    let(:latency) { settings.sidekiq.acceptable_queue_latency - 1 }

    before do
      allow(Sidekiq::Queue).to receive(:new).and_return(queue)
      allow(DPN::Workers).to receive(:nodes).and_return([local_node])
    end

    def check_status(status)
      get '/status'
      expect(last_response.status).to eq status
    end

    context 'success' do
      before do
        allow(local_node).to receive(:alive?).and_return(true)
      end
      it 'when everything is OK - it responds with 200 status' do
        check_status 200
        expect(last_response.body).to match(/OK:/)
      end
      it 'the response contains an application version' do
        check_status 200
        expect(last_response.body).to include("DpnSync: #{DpnSync::VERSION}")
      end
    end

    context 'DPN-network failures' do
      context 'when a node is not alive' do
        before do
          allow(local_node).to receive(:alive?).and_return(false)
        end
        it 'when a node is not alive - it responds with 500 status' do
          check_status 500
          expect(last_response.body).to match(/WARNING:/)
        end
        it 'the response contains an application version' do
          check_status 500
          expect(last_response.body).to include("DpnSync: #{DpnSync::VERSION}")
        end
      end
    end

    context 'Sidekiq failures' do
      context 'when the queue' do
        it 'is too large - it responds with 500 status' do
          size = settings.sidekiq.acceptable_queue_size + 1
          allow(queue).to receive(:size).and_return(size)
          check_status 500
          expect(last_response.body).to match(/WARNING:/)
        end
        it 'is too slow - it responds with 500 status' do
          latency = settings.sidekiq.acceptable_queue_latency + 1
          allow(queue).to receive(:latency).and_return(latency)
          check_status 500
          expect(last_response.body).to match(/WARNING:/)
        end
      end
    end
  end

  describe 'GET /test' do
    it 'responds with a message entry form' do
      get '/test'
      expect(last_response.body).to match(/form method="post" action="msg"/)
    end

    it 'displays job stats' do
      stats = double(Sidekiq::Stats)
      expect(stats).to receive(:processed).and_return(5)
      expect(stats).to receive(:failed).and_return(5)
      expect(stats).to receive(:enqueued).and_return(5)
      expect(Sidekiq::Stats).to receive(:new).and_return(stats)
      get '/test'
      expect(last_response.body).to match(/Failed:.*5/)
      expect(last_response.body).to match(/Processed:.*5/)
      expect(last_response.body).to match(/Enqueued:.*5/)
    end

    it 'displays messages' do
      expect(REDIS).to receive(:lrange).and_return(['a', 'b'])
      get '/test'
      expect(last_response.body).to match(/<h3>Timestamps Processed<\/h3>\n.*<p>a<\/p>\n.*<p>b<\/p>\n/)
    end
  end

  describe 'POST /msg' do
    let(:msg) { Time.now.utc.httpdate }

    it 'initiates async message processing' do
      expect(DPN::Workers::TestWorker).to receive(:perform_async)
      post '/msg', msg: msg
    end

    it 'redirects to the /test page' do
      post '/msg', msg: msg
      expect(last_response.status).to eq 302
      expect(last_response.location).to match(/\/test$/)
    end
  end

  describe 'POST /msg/clear' do
    it 'calls DPN::Workers::TestMessages.clear' do
      expect(DPN::Workers::TestMessages).to receive(:clear)
      post '/msg/clear'
    end

    it 'redirects to the /test page' do
      post '/msg/clear'
      expect(last_response.status).to eq 302
      expect(last_response.location).to match(/\/test$/)
    end
  end

  describe 'POST /msg/fail' do
    it 'initiates async message processing' do
      expect(DPN::Workers::TestWorker).to receive(:perform_async).with(/fail/i)
      post '/msg/fail'
    end

    it 'redirects to the /test page' do
      post '/msg/fail'
      expect(last_response.status).to eq 302
      expect(last_response.location).to match(/\/test$/)
    end
  end
end
