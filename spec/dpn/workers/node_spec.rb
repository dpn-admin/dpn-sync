# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::Node, :vcr do
  let(:subject) { local_node }
  let(:client) { subject.client }

  describe '#new' do
    it 'works' do
      expect(subject).to be_an described_class
    end
  end

  describe '#alive?' do
    it 'works' do
      expect(subject.alive?).to be true
    end
    it 'is true when node is alive' do
      response = double(DPN::Client::Response)
      expect(response).to receive(:success?).and_return(true)
      expect(client).to receive(:node).and_return(response)
      expect(subject.alive?).to be true
    end
    it 'is false when node is not alive' do
      response = double(DPN::Client::Response)
      expect(response).to receive(:success?).and_return(false)
      expect(client).to receive(:node).and_return(response)
      expect(subject.alive?).to be false
    end
  end

  describe '#status' do
    it 'works' do
      expect(subject.status).not_to be_nil
    end
    it 'contains OK when node is alive' do
      expect(subject).to receive(:alive?).and_return(true)
      expect(subject.status).to include 'OK'
    end
    it 'contains WARNING when node is not alive' do
      expect(subject).to receive(:alive?).and_return(false)
      expect(subject.status).to include 'WARNING'
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
      expect(subject.to_hash).not_to be_nil
    end
    it 'is a Hash' do
      expect(subject.to_hash).to be_an Hash
    end
    it 'includes :namespace' do
      expect(subject.to_hash).to include(:namespace)
    end
    it 'includes :api_root' do
      expect(subject.to_hash).to include(:api_root)
    end
    it 'includes :auth_credential' do
      expect(subject.to_hash).to include(:auth_credential)
    end
    it 'includes additional node attributes after update' do
      expect(subject.update).to be true
      hash = subject.to_hash
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
      expect(subject.update).not_to be_nil
    end
    it 'is true for a successful update' do
      expect(subject.update).to be true
    end
    context 'failure' do
      it 'raises exception' do
        expect { example_node.update }.to raise_error(SocketError)
      end
    end
  end
end
