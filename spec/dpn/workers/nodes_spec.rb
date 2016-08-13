# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::Nodes do
  let(:settings) { SyncSettings }
  let(:node_data) { settings.nodes.map(&:to_hash) }
  let(:node_names) { settings.nodes.map(&:namespace) }
  let(:local_namespace) { settings.local_namespace }
  let(:subject) { described_class.new(node_data, local_namespace) }

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
    def sync_instance(sync_class)
      sync_instance = double(sync_class)
      expect(sync_class).to receive(:new).at_least(:once).and_return(sync_instance)
      expect(sync_instance).to receive(:sync).at_least(:once).and_return(true)
    end

    def it_can_sync(class_name)
      sync_class = class_name.constantize
      sync_instance sync_class
      expect(subject).to receive(:sync_data).with(sync_class).and_call_original
      result = subject.sync(class_name)
      expect(result).to be true
    end

    context 'success' do
      it 'can sync bags' do
        it_can_sync 'DPN::Workers::SyncBags'
      end
      it 'can sync members' do
        it_can_sync 'DPN::Workers::SyncMembers'
      end
      it 'can sync nodes' do
        it_can_sync 'DPN::Workers::SyncNodes'
      end
      it 'can sync replication requests' do
        it_can_sync 'DPN::Workers::SyncReplications'
      end
    end

    context 'failure' do
      it 'returns false for an unknown class_name' do
        result = subject.sync('unknown')
        expect(result).to be false
      end
      it 'returns false for a class that fails to implement #sync' do
        result = subject.sync('DPN::Workers::Sync')
        expect(result).to be false
      end
      it 'logs errors false for unknown content' do
        logger = subject.send(:logger)
        expect(logger).to receive(:error).exactly(:once)
        result = subject.sync('unknown')
        expect(result).to be false
      end
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
