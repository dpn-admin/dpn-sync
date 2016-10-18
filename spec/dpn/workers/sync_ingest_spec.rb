# -*- encoding: utf-8 -*-
require 'spec_helper'
require 'shared_examples/sync_content'

describe DPN::Workers::SyncIngest, :vcr do
  let(:ingest) do
    {
      ingest_id: uuid,
      bag: "9998e960-fc6d-44f4-9d73-9a60a8eae609",
      ingested: true,
      replicating_nodes: [
        "hathi",
        "chron",
        "aptrust"
      ],
      created_at: "2015-02-25T16:24:02.000Z"
    }
  end

  let(:time) { Time.now.utc.iso8601 }
  let(:uuid) { "1b49a2aa-6a2a-48db-a44b-28b2df1bc0e6" }
  let(:node_client) { local_node.client }
  let(:subject) { described_class.new ingest, node_client, null_logger }

  it_behaves_like 'sync_content'

  ##
  # PRIVATE

  describe '#content_id' do
    it 'returns a ingest ID' do
      id = subject.send(:content_id)
      expect(id).to be_an String
      expect(id).to eq uuid
    end
  end

  describe '#create' do
    context 'success' do
      before do
        response = double('response')
        allow(response).to receive(:success?).and_return(true)
        allow(response).to receive(:body).and_return('horray!')
        allow(response).to receive(:status).and_return(200)
        allow(node_client).to receive(:create_ingest).and_return(response)
      end
      it 'returns true for successful requests to node_client.create_ingest' do
        expect(subject.send(:create)).to be true
      end
      it 'logs info from requests to node_client.create_ingest' do
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
        allow(node_client).to receive(:create_ingest).and_return(response)
      end
      it 'returns false for failing requests to node_client.create_ingest' do
        expect(subject.send(:create)).to be false
      end
      it 'logs errors from requests to node_client.create_ingest' do
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
