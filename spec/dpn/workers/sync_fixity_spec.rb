# -*- encoding: utf-8 -*-
require 'spec_helper'
require 'shared_examples/sync_content'

describe DPN::Workers::SyncFixity do
  let(:fixity) do
    {
      fixity_check_id: uuid,
      created_at: "2015-09-15T17:56:03Z",
      fixity_at: "2015-09-15T17:56:03Z",
      success: true,
      bag: "00000000-0000-4000-a000-000000000001",
      node: "sdr"
    }
  end

  let(:time) { Time.now.utc.iso8601 }
  let(:uuid) { '1729db55-13d3-467b-8b6d-7cc21d88a48a' }
  let(:node_client) { local_node.client }
  let(:subject) { described_class.new fixity, node_client, null_logger }

  it_behaves_like 'sync_content'

  ##
  # PRIVATE

  describe '#content_id' do
    it 'returns a fixity ID' do
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
        allow(node_client).to receive(:create_fixity_check).and_return(response)
      end
      it 'returns true for successful requests to node_client.create_fixity_check' do
        expect(subject.send(:create)).to be true
      end
      it 'logs info from requests to node_client.create_fixity_check' do
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
        allow(node_client).to receive(:create_fixity_check).and_return(response)
      end
      it 'returns false for failing requests to node_client.create_fixity_check' do
        expect(subject.send(:create)).to be false
      end
      it 'logs errors from requests to node_client.create_fixity_check' do
        logger = subject.send(:logger)
        expect(logger).to receive(:error).at_least(:once).and_call_original
        expect(subject.send(:create)).to be false
      end
    end
  end

  describe '#update' do
    # Fixity is read-only; allow `update` to be always true to skip it.
    context 'success' do
      it 'returns true (always)' do
        expect(subject.send(:update)).to be true
      end
    end
  end
end
