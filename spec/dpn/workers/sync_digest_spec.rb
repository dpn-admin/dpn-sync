# -*- encoding: utf-8 -*-
require 'spec_helper'
require 'shared_examples/sync_content'

describe DPN::Workers::SyncDigest, :vcr do
  let(:digest) do
    {
      value: "e39a201a88bc3d7803a5e375d9752439d328c2e85b4f1ba70a6d984b6c5378bd",
      created_at: "2015-09-15T19:38:31Z",
      bag: bag_id,
      node: "aptrust",
      algorithm: algorithm
    }
  end
  let(:time) { Time.now.utc.iso8601 }
  let(:digest_id) { "#{algorithm}: #{bag_id}" }
  let(:bag_id) { '00000000-0000-4000-a000-000000000001' }
  let(:algorithm) { 'sha256' }
  let(:node_client) { local_node.client }
  let(:subject) { described_class.new digest, node_client, null_logger }

  it_behaves_like 'sync_content'

  ##
  # PRIVATE

  describe '#content_id' do
    it 'returns a digest ID' do
      id = subject.send(:content_id)
      expect(id).to be_an String
      expect(id).to eq digest_id
    end
  end

  describe '#create' do
    context 'success' do
      before do
        response = double('response')
        allow(response).to receive(:success?).and_return(true)
        allow(response).to receive(:body).and_return('horray!')
        allow(response).to receive(:status).and_return(200)
        allow(node_client).to receive(:create_digest).and_return(response)
      end
      it 'returns true for successful requests to node_client.create_digest' do
        expect(subject.send(:create)).to be true
      end
      it 'logs info from requests to node_client.create_digest' do
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
        allow(node_client).to receive(:create_digest).and_return(response)
      end
      it 'returns false for failing requests to node_client.create_digest' do
        expect(subject.send(:create)).to be false
      end
      it 'logs errors from requests to node_client.create_digest' do
        logger = subject.send(:logger)
        expect(logger).to receive(:error).at_least(:once).and_call_original
        expect(subject.send(:create)).to be false
      end
    end
  end

  describe '#update' do
    # Digest is read-only; allow `update` to be always true to skip it.
    context 'success' do
      it 'returns true (always)' do
        expect(subject.send(:update)).to be true
      end
    end
  end
end
