require 'spec_helper'

describe DPN::DpnSync, :vcr do
  let(:settings) { SyncSettings }

  describe 'GET /status' do
    let(:app_version) { "dpn-sync: #{DPN::DpnSync::VERSION}" }
    let(:queue) do
      queue = instance_double(Sidekiq::Queue)
      allow(queue).to receive(:size).and_return(size)
      allow(queue).to receive(:latency).and_return(latency)
      queue
    end
    let(:size) { settings.sidekiq.acceptable_queue_size - 1 }
    let(:latency) { settings.sidekiq.acceptable_queue_latency - 1 }

    let(:node_checker) { DPN::DpnNodeCheck.new(remote_node) }
    let(:node_check_name) { "external-node-#{remote_node.namespace}" }

    before do
      # The Sidekiq defaults provide passing checks;
      # ensure these defaults take effect in OkComputer.
      allow(Sidekiq::Queue).to receive(:new).and_return(queue)
      OkComputer::Registry.deregister 'feature-sidekiq'
      OkComputer::Registry.register 'feature-sidekiq', DPN::SidekiqCheck.new
      # Re-register the node checker for each spec.
      allow(remote_node).to receive(:alive?).and_return(true)
      OkComputer::Registry.deregister node_check_name
      OkComputer::Registry.register node_check_name, node_checker
    end

    after do
      # Re-register the node checker for each spec.
      allow(DPN::DpnNodeCheck).to receive(:new).and_call_original
      checker = DPN::DpnNodeCheck.new(remote_node)
      check_name = "external-node-#{remote_node.namespace}"
      OkComputer::Registry.deregister check_name
      OkComputer::Registry.register check_name, checker
      # Re-register the version checker
      allow(DPN::AppVersionMonitor).to receive(:new).and_call_original
      version_monitor = DPN::AppVersionMonitor.new
      OkComputer::Registry.deregister 'version'
      OkComputer::Registry.register 'version', DPN::DpnCheck.new(version_monitor)
    end

    def check_status(path = '/status', status = 200)
      get path
      expect(last_response.status).to eq status
    end

    def check_passed(path = '/status')
      check_status path, 200
      expect(last_response.body).to match(/PASSED:/)
    end

    def check_failed(path = '/status')
      check_status path, 500
      expect(last_response.body).to match(/FAILED:/)
    end

    def check_passed_json(path = '/status')
      check_status path + '.json', 200
      data = last_response.body
      expect(data).to match(/PASSED:/)
      expect { JSON.parse(data) }.not_to raise_error
    end

    it 'GET /status returns 200 and JSON data' do
      check_passed_json '/status'
    end

    it 'returns 404 status when a check is not found' do
      get '/status/wtf'
      expect(last_response.status).to eq 404
    end

    context 'GET /status route handles exceptions' do
      before do
        err = RuntimeError.new('status_error')
        allow(OkComputer::Registry).to receive(:all).and_raise(err)
      end
      after do
        allow(OkComputer::Registry).to receive(:all).and_call_original
      end
      it 'returns 500 with an error for exceptions' do
        get '/status'
        expect(last_response.status).to eq 500
        expect(last_response.body).to include('status_error')
      end
    end

    context 'GET /status/{check_name} route handles exceptions' do
      before do
        err = RuntimeError.new('status_error')
        allow(OkComputer::Registry).to receive(:fetch).and_raise(err)
      end
      after do
        allow(OkComputer::Registry).to receive(:fetch).and_call_original
      end
      it 'returns 500 with an error for exceptions' do
        get '/status/version'
        expect(last_response.status).to eq 500
        expect(last_response.body).to include('status_error')
      end
    end

    context 'a DPN::Check handles exceptions' do
      before do
        version_monitor = instance_double(DPN::AppVersionMonitor)
        allow(DPN::AppVersionMonitor).to receive(:new).and_return(version_monitor)
        allow(version_monitor).to receive(:ok?).and_raise(RuntimeError.new('version_error'))
        # Re-register the version checker
        OkComputer::Registry.deregister 'version'
        OkComputer::Registry.register 'version', DPN::DpnCheck.new(version_monitor)
      end
      it 'returns 500 with an error for exceptions' do
        get '/status/version'
        expect(last_response.status).to eq 500
        expect(last_response.body).to include('version_error')
      end
    end

    context 'DPN-network alive' do
      it 'returns 200 status when all checks are passing' do
        check_passed
      end
      it 'the application version is present' do
        check_passed
        expect(last_response.body).to include(app_version)
      end
    end

    context 'DPN-network dead' do
      before do
        allow(remote_node).to receive(:alive?).and_return(false)
      end
      it 'returns 500 status when a check is failing' do
        check_failed
      end
      it 'the application version is present' do
        check_failed
        expect(last_response.body).to include(app_version)
      end
    end

    context 'GET /status/external-{remote-node}' do
      it 'returns 200 status when node is responding' do
        check_passed "/status/#{node_check_name}"
      end
      it 'returns 200 status and JSON data' do
        check_passed_json "/status/#{node_check_name}"
      end
      it 'returns 500 status when node is not responding' do
        allow(remote_node).to receive(:alive?).and_return(false)
        check_failed "/status/#{node_check_name}"
      end
    end

    context 'Sidekiq' do
      it 'returns 200 status when Sidekiq queue is OK' do
        check_passed '/status'
        check_passed '/status/feature-sidekiq'
      end
      it 'returns 500 status when the queue is too large' do
        size = settings.sidekiq.acceptable_queue_size + 1
        allow(queue).to receive(:size).and_return(size)
        check_failed '/status'
        check_failed '/status/feature-sidekiq'
      end
      it 'returns 500 status when the queue is too slow' do
        latency = settings.sidekiq.acceptable_queue_latency + 1
        allow(queue).to receive(:latency).and_return(latency)
        check_failed '/status'
        check_failed '/status/feature-sidekiq'
      end
    end
  end
end
