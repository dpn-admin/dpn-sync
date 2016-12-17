# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::BagStores do
  subject(:replication_worker) { described_class.new }
  let(:client) { replication_worker.send(:local_client) }
  let(:response) { double(DPN::Client::Response) }

  # The replication data is irrelevant to the bag store worker, use a dummy
  let(:replication) { { replication_id: 'test' } }

  before do
    allow(response).to receive(:body).and_return(replication)
    allow(response).to receive(:success?).and_return(true)
    allow(client).to receive(:replications).and_yield(response)
  end

  describe '#perform' do
    let!(:bag_store) { DPN::Workers::BagStore.new replication }
    before do
      allow(DPN::Workers::BagStore).to receive(:new).and_return(bag_store)
    end
    it 'returns true for success' do
      allow(bag_store).to receive(:transfer).and_return(true)
      result = replication_worker.perform
      expect(result).to be true
    end
    it 'returns false for failure' do
      allow(bag_store).to receive(:transfer).and_return(false)
      result = replication_worker.perform
      expect(result).to be false
    end
    it 'raises exceptions' do
      allow(bag_store).to receive(:transfer).and_raise('failed')
      expect { replication_worker.perform }.to raise_error(RuntimeError)
    end
  end

  #
  # PRIVATE
  #

  describe '#replications_query' do
    let(:query) { replication_worker.send(:replications_query) }
    it 'returns a Hash' do
      expect(query).to be_an Hash
    end
    it 'query[:cancelled] is false' do
      expect(query).to include(:cancelled)
      expect(query[:cancelled]).to be false
    end
    it 'query[:store_requested] is true' do
      expect(query).to include(:store_requested)
      expect(query[:store_requested]).to be true
    end
    it 'query[:stored] is false' do
      expect(query).to include(:stored)
      expect(query[:stored]).to be false
    end
    it 'query[:to_node] is the local node namespace' do
      expect(query).to include(:to_node)
      expect(query[:to_node]).to eq local_node.namespace
    end
  end
end
