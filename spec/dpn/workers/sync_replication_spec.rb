# -*- encoding: utf-8 -*-
require 'spec_helper'
require 'shared_examples/sync_content'

describe DPN::Workers::SyncReplication, :vcr do
  let(:node_client) { local_node.client }
  let(:subject) { described_class.new replication, node_client, null_logger }

  it_behaves_like 'sync_content'

  ##
  # PRIVATE

  describe '#content_id' do
    it 'returns a replication_id' do
      id = subject.send(:content_id)
      expect(id).to be_an String
      expect(id).to eq replication[:replication_id]
    end
  end

  describe '#create' do
    context 'success' do
      before do
        response = double('response')
        allow(response).to receive(:success?).and_return(true)
        allow(response).to receive(:body).and_return('horray!')
        allow(response).to receive(:status).and_return(200)
        allow(node_client).to receive(:create_replication).and_return(response)
      end
      it 'returns true for successful requests to node_client.create_replication' do
        expect(subject.send(:create)).to be true
      end
      it 'logs info from requests to node_client.create_replication' do
        logger = subject.send(:logger)
        expect(logger).to receive(:info).at_least(:once).and_call_original
        expect(subject.send(:create)).to be true
      end
    end
    context 'failure' do
      before do
        response = double('response')
        allow(response).to receive(:success?).and_return(false)
        allow(response).to receive(:body).and_return('error message')
        allow(response).to receive(:status).and_return(400)
        allow(node_client).to receive(:create_replication).and_return(response)
      end
      it 'returns false for failing requests to node_client.create_replication' do
        expect(subject.send(:create)).to be false
      end
      it 'logs errors from requests to node_client.create_replication' do
        logger = subject.send(:logger)
        expect(logger).to receive(:error).at_least(:once).and_call_original
        expect(subject.send(:create)).to be false
      end
    end
  end

  describe '#update' do
    context 'success' do
      before do
        response = double('response')
        allow(response).to receive(:success?).and_return(true)
        allow(response).to receive(:body).and_return('horray!')
        allow(response).to receive(:status).and_return(200)
        allow(node_client).to receive(:update_replication).and_return(response)
      end
      it 'returns true for successful requests to node_client.update_replication' do
        expect(subject.send(:update)).to be true
      end
      it 'logs info from requests to node_client.update_replication' do
        logger = subject.send(:logger)
        expect(logger).to receive(:info).at_least(:once).and_call_original
        expect(subject.send(:update)).to be true
      end
    end
    context 'failure' do
      before do
        response = double('response')
        allow(response).to receive(:success?).and_return(false)
        allow(response).to receive(:body).and_return('error message')
        allow(response).to receive(:status).and_return(400)
        allow(node_client).to receive(:update_replication).and_return(response)
      end
      it 'returns false for failing requests to node_client.update_replication' do
        expect(subject.send(:update)).to be false
      end
      it 'logs errors from requests to node_client.update_replication' do
        logger = subject.send(:logger)
        expect(logger).to receive(:error).at_least(:once).and_call_original
        expect(subject.send(:update)).to be false
      end
    end
  end
end
