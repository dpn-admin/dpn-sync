# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::Node, :vcr do
  subject(:node) { local_node }
  let(:client) { node.client }

  describe '#new' do
    it 'works' do
      expect(node).to be_an described_class
    end
  end

  describe '#alive?' do
    it 'works' do
      expect(node.alive?).to be true
    end
    it 'is true when node is alive' do
      response = double(DPN::Client::Response)
      expect(response).to receive(:success?).and_return(true)
      expect(client).to receive(:node).and_return(response)
      expect(node.alive?).to be true
    end
    it 'is false when node is not alive' do
      response = double(DPN::Client::Response)
      expect(response).to receive(:success?).and_return(false)
      expect(client).to receive(:node).and_return(response)
      expect(node.alive?).to be false
    end
    it 'is false when node check raises an exception' do
      expect(client).to receive(:node).and_raise(RuntimeError)
      expect(node.alive?).to be false
    end
  end

  describe '#status' do
    it 'works' do
      expect(node.status).not_to be_nil
    end
    it 'contains PASSED when node is alive' do
      expect(node).to receive(:alive?).and_return(true)
      expect(node.status).to include 'PASSED'
    end
    it 'contains FAILED when node is not alive' do
      expect(node).to receive(:alive?).and_return(false)
      expect(node.status).to include 'FAILED'
    end
  end

  describe '#client' do
    it 'works' do
      expect(client).not_to be_nil
    end
    it 'is a DPN::Client::Agent' do
      expect(client).to be_an DPN::Client::Agent
    end
  end

  describe '#to_hash' do
    it 'works' do
      expect(node.to_hash).not_to be_nil
    end
    it 'is a Hash' do
      expect(node.to_hash).to be_an Hash
    end
    it 'includes :namespace' do
      expect(node.to_hash).to include(:namespace)
    end
    it 'includes :api_root' do
      expect(node.to_hash).to include(:api_root)
    end
    it 'includes :auth_credential' do
      expect(node.to_hash).to include(:auth_credential)
    end
    it 'includes additional node attributes after update' do
      expect(node.update).to be true
      hash = node.to_hash
      expect(hash).to include(:name)
      expect(hash).to include(:ssh_pubkey)
      expect(hash).to include(:created_at)
      expect(hash).to include(:updated_at)
      expect(hash).to include(:replicate_from)
      expect(hash).to include(:replicate_to)
      expect(hash).to include(:restore_from)
      expect(hash).to include(:restore_to)
      expect(hash).to include(:protocols)
      expect(hash).to include(:fixity_algorithms)
      expect(hash).to include(:storage)
    end
  end

  describe '#update' do
    it 'works' do
      expect(node.update).not_to be_nil
    end
    it 'is true for a successful update' do
      expect(node.update).to be true
    end
    context 'failure' do
      it 'raises exception' do
        expect { example_node.update }.to raise_error(SocketError)
      end
    end
  end
end
