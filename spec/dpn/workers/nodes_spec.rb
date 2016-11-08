# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::Nodes, :vcr do
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
      sync_instance class_name.constantize
      expect(subject).to receive(:sync_data).with(class_name).and_call_original
      result = subject.sync(class_name)
      expect(result).to be true
    end

    context 'success' do
      it 'can sync bags' do
        it_can_sync 'DPN::Workers::SyncBags'
      end
      it 'can sync digests' do
        it_can_sync 'DPN::Workers::SyncDigests'
      end
      it 'can sync fixities' do
        it_can_sync 'DPN::Workers::SyncFixities'
      end
      it 'can sync ingests' do
        it_can_sync 'DPN::Workers::SyncIngests'
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
      it 'raises NameError for an unknown class_name' do
        expect { subject.sync('unknown') }.to raise_error(NameError)
      end
      it 'raises NotImplementedError for a class that does not implement #sync' do
        expect { subject.sync('DPN::Workers::Sync') }.to raise_error(NotImplementedError)
      end
      it 'logs exceptions for unknown content' do
        logger = subject.send(:logger)
        expect(logger).to receive(:error).exactly(:once)
        expect { subject.sync('unknown') }.to raise_error(NameError)
      end
    end
  end

  context 'private' do
    describe 'sync_data' do
      it 'iterates on remote_nodes' do
        node_count = subject.remote_nodes.count
        expect(DPN::Workers::SyncNodes).to receive(:new).exactly(node_count).and_call_original
        subject.send(:sync_data, 'DPN::Workers::SyncNodes')
      end

      it 'can skip a remote_node failure' do
        # Add an example_node that will fail to connect
        subject.nodes << example_node
        node_count = subject.remote_nodes.count
        expect(DPN::Workers::SyncNodes).to receive(:new).exactly(node_count).and_call_original
        result = subject.send(:sync_data, 'DPN::Workers::SyncNodes')
        expect(result).to be false
      end
    end
  end
end
