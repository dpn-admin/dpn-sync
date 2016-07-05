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
      expect(subject).to receive(:sync_bags)
      result = subject.sync(:bags) # Symbol arg is OK
      expect(result).to be true
    end
    it 'can sync nodes' do
      expect(subject).to receive(:sync_nodes)
      result = subject.sync('nodes') # String arg is OK
      expect(result).to be true
    end
  end

  context 'private' do
    let!(:sync) do
      local_node = subject.local_node
      remote_node = subject.remote_nodes.sample(1).first
      syncer = DPN::Workers::Sync.new(local_node, remote_node)
      expect(syncer).to receive(:sync).at_least(:once)
      syncer
    end

    describe 'sync_bags' do
      it 'iterates on remote_nodes' do
        expect(subject).to receive(:remote_nodes).and_call_original
        expect(DPN::Workers::SyncBags).to receive(:new).at_least(:once).and_return(sync)
        subject.send(:sync_bags)
      end
    end

    describe 'sync_nodes' do
      it 'iterates on remote_nodes' do
        expect(subject).to receive(:remote_nodes).and_call_original
        expect(DPN::Workers::SyncNodes).to receive(:new).at_least(:once).and_return(sync)
        subject.send(:sync_nodes)
      end
    end
  end
end
