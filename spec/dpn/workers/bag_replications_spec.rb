# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::BagReplications do
  let(:replication_worker) { subject }
  let(:client) { replication_worker.send(:local_client) }
  let(:response) { double(DPN::Client::Response) }

  before do
    allow(response).to receive(:body).and_return(replication)
    allow(response).to receive(:success?).and_return(true)
    allow(client).to receive(:replications).and_yield(response)
  end

  describe '#perform' do
    let(:replicator) { DPN::Workers::BagReplication.new replication }
    before do
      allow(DPN::Workers::BagReplication).to receive(:new).and_return(replicator)
    end
    it 'returns true for success' do
      allow(replicator).to receive(:replicate).and_return(true)
      result = replication_worker.perform
      expect(result).to be true
    end
    it 'returns false for failure' do
      allow(replicator).to receive(:replicate).and_return(false)
      result = replication_worker.perform
      expect(result).to be false
    end
    it 'raises exceptions' do
      allow(replicator).to receive(:replicate).and_raise('failed')
      expect { replication_worker.perform }.to raise_error(RuntimeError)
    end
  end

  #
  # PRIVATE
  #

  describe '#replications' do
    let(:repls) { replication_worker.send(:replications) }
    it 'returns a Array<Hash>' do
      expect(repls).to be_an Array
    end
    it 'returns a Array with Hash elements' do
      expect(repls.first).to be_an Hash
    end
  end

  describe '#replications_query' do
    let(:query) { replication_worker.send(:replications_query) }
    it 'returns a Hash' do
      expect(query).to be_an Hash
    end
    it 'query[:cancelled] is a field' do
      expect(query).to include(:cancelled)
    end
    it 'query[:cancelled] is false' do
      expect(query[:cancelled]).to be false
    end
    it 'query[:store_requested] is a field' do
      expect(query).to include(:store_requested)
    end
    it 'query[:store_requested] is true' do
      expect(query[:store_requested]).to be true
    end
    it 'query[:stored] is a field' do
      expect(query).to include(:stored)
    end
    it 'query[:stored] is false' do
      expect(query[:stored]).to be false
    end
    it 'query[:to_node] is a field' do
      expect(query).to include(:to_node)
    end
    it 'query[:to_node] is the local node namespace' do
      expect(query[:to_node]).to eq local_node.namespace
    end
  end

  describe '#logger' do
    let(:logger) { replication_worker.send(:logger) }
    it 'returns a Logger' do
      expect(logger).to be_an Logger
    end
  end

  describe '#local_client' do
    it 'returns a DPN::Client::Agent' do
      expect(client).to be_an DPN::Client::Agent
    end
    it 'the client.user_agent includes the local node namespace' do
      expect(client.user_agent).to include SyncSettings.local_namespace
    end
  end

  describe '#local_node' do
    let(:node) { replication_worker.send(:local_node) }
    it 'returns a DPN::Workers::Node' do
      expect(node).to be_an DPN::Workers::Node
    end
    it 'the node.namespace is the local node namespace' do
      expect(node.namespace).to eq SyncSettings.local_namespace
    end
  end

  describe '#nodes' do
    let(:nodes) { replication_worker.send(:nodes) }
    it 'returns a DPN::Workers::Nodes' do
      expect(nodes).to be_an DPN::Workers::Nodes
    end
  end
end
