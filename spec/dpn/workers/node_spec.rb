# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::Node, :vcr do
  let(:example_node) do
    described_class.new(
      namespace: 'example',
      api_root: 'http://node.example.org',
      auth_credential: 'example_token'
    )
  end

  let(:local_node) { DPN::Workers.nodes.local_node }

  let(:subject) { local_node }

  describe '#new' do
    it 'works' do
      expect(example_node).to be_an described_class
    end
  end

  describe '#alive?' do
    it 'works' do
      expect(subject.alive?).to be true
    end
  end

  describe '#client' do
    it 'works' do
      expect(subject.client).not_to be_nil
    end
    it 'is a DPN::Client::Agent' do
      expect(subject.client).to be_an DPN::Client::Agent
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
      expect(subject.to_hash).to include(:name)
      expect(subject.to_hash).to include(:ssh_pubkey)
      expect(subject.to_hash).to include(:created_at)
      expect(subject.to_hash).to include(:updated_at)
      expect(subject.to_hash).to include(:replicate_from)
      expect(subject.to_hash).to include(:replicate_to)
      expect(subject.to_hash).to include(:restore_from)
      expect(subject.to_hash).to include(:restore_to)
      expect(subject.to_hash).to include(:protocols)
      expect(subject.to_hash).to include(:fixity_algorithms)
      expect(subject.to_hash).to include(:storage)
    end
  end

  describe '#update' do
    it 'works' do
      expect(subject.update).not_to be_nil
    end
    it 'is true for a successful update' do
      expect(subject.update).to be true
    end
    it 'is false on failure to update' do
      expect(example_node.update).to be false
    end
    it 'logs errors on failure to retrieve node data' do
      logger = example_node.send(:logger)
      expect(logger).to receive(:error)
      expect(example_node.update).to be false
    end
  end
end
