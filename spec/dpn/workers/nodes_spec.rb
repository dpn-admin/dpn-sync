# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::Nodes do
  let(:nodes) { Settings.nodes.map(&:to_hash) }
  let(:node_names) { Settings.nodes.map(&:namespace) }
  let(:local_namespace) { Settings.local_namespace }
  subject { described_class.new(nodes, local_namespace) }

  describe '#new' do
    it 'works' do
      expect(subject).to be_an described_class
    end
  end

  describe '#each' do
    it 'works' do
      result = subject.each { |node| }
      expect(result).not_to be_nil
    end
    it 'yields Array<DPN::Workers::Node>' do
      result = subject.each { |node| }
      expect(result).to be_an Array
      expect(result.first).to be_an DPN::Workers::Node
    end
  end

  describe '#local_node' do
    it 'works' do
      expect(subject.local_node).to be_an DPN::Workers::Node
    end
    it 'returns the local_namespace node' do
      expect(subject.local_node.namespace).to eq local_namespace
    end
  end

  describe '#node' do
    it 'works' do
      namespace = node_names.sample(1).first
      result = subject.node(namespace)
      expect(result).to be_an DPN::Workers::Node
    end
    it 'returns nil for invalid namespace' do
      result = subject.remote_node('invalid')
      expect(result).to be_nil
    end
  end

  describe '#remote_node' do
    it 'works' do
      namespace = node_names.select { |n| n != local_namespace }.sample(1).first
      result = subject.remote_node(namespace)
      expect(result).to be_an DPN::Workers::Node
    end
    it 'returns nil for invalid namespace' do
      result = subject.remote_node('invalid')
      expect(result).to be_nil
    end
    it 'returns nil for local namespace' do
      result = subject.remote_node(local_namespace)
      expect(result).to be_nil
    end
  end

  describe '#remote_nodes' do
    it 'works' do
      result = subject.remote_nodes
      expect(result).not_to be_nil
    end
    it 'returns Array<DPN::Workers::Node>' do
      result = subject.remote_nodes
      expect(result).to be_an Array
      expect(result.first).to be_an DPN::Workers::Node
    end
  end

  describe '#sync' do
    it 'works' do
      result = subject.sync(:something)
      expect(result).not_to be_nil
    end
    it 'returns false for unknown content' do
      result = subject.sync(:unknown)
      expect(result).to be false
    end
    it 'can sync bags' do
      expect(subject).to receive(:sync_data).with(DPN::Workers::SyncBags)
      result = subject.sync(:bags) # String or Symbol arg is OK
      expect(result).to be true
    end
    it 'can sync members' do
      expect(subject).to receive(:sync_data).with(DPN::Workers::SyncMembers)
      result = subject.sync('members') # String or Symbol arg is OK
      expect(result).to be true
    end
    it 'can sync nodes' do
      expect(subject).to receive(:sync_data).with(DPN::Workers::SyncNodes)
      result = subject.sync('nodes') # String or Symbol arg is OK
      expect(result).to be true
    end
  end

  context 'private' do
    describe 'sync_data' do
      let(:syncer) do
        syncer = double(DPN::Workers::Sync)
        expect(syncer).to receive(:sync).at_least(:once)
        syncer
      end

      it 'iterates on remote_nodes' do
        node_count = subject.remote_nodes.count
        expect(subject).to receive(:remote_nodes).and_call_original
        expect(DPN::Workers::SyncBags).to receive(:new).exactly(node_count).and_return(syncer)
        subject.send(:sync_data, DPN::Workers::SyncBags)
      end
    end
  end
end
