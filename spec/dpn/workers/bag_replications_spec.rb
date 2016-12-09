# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::BagReplications, :vcr do
  subject(:replication_worker) { described_class.new }
  let(:client) { replication_worker.send(:local_client) }

  describe '#perform' do
    it 'calls #bag_transfers' do
      expect(replication_worker).to receive(:bag_transfers)
      replication_worker.perform
    end
  end

  #
  # PRIVATE
  #

  describe '#bag_transfers' do
    it 'is an abstract method that raises NotImplementedError' do
      expect do
        replication_worker.send(:bag_transfers)
      end.to raise_error NotImplementedError
    end
  end

  describe '#replications' do
    let(:repls) { replication_worker.send(:replications) }
    let(:response) { double(DPN::Client::Response) }
    before do
      allow(response).to receive(:body).and_return(replication)
      allow(response).to receive(:success?).and_return(true)
      allow(client).to receive(:replications).and_yield(response)
      allow(replication_worker).to receive(:replications_query).and_return({})
    end
    it 'returns a Array<Hash>' do
      expect(repls).to be_an Array
    end
    it 'returns a Array with Hash elements' do
      expect(repls.first).to be_an Hash
    end
  end

  describe '#replications_query' do
    let(:query) { replication_worker.send(:replications_query) }
    it 'is an abstract method that raises NotImplementedError' do
      expect { query }.to raise_error(NotImplementedError)
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
