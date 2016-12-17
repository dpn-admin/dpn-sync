# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::Replication, :vcr do
  subject(:replicator) { described_class.new replication }

  it 'works' do
    expect(replicator).to be_an described_class
  end

  it 'has accessors for replication fields' do
    replication.keys do |key|
      expect(replicator).to respond_to(key.to_sym)
    end
  end

  it 'the accessors for replication fields return replication values' do
    replication.keys do |key|
      expect(replicator.send(key)).to eq(replication[key])
    end
  end

  describe '#id' do
    it 'exists' do
      expect(replicator).to respond_to(:id)
    end
    it 'works' do
      expect(replicator.id).not_to be_nil
    end
    it 'returns a String' do
      expect(replicator.id).to be_an String
    end
    it 'returns the replication[:replication_id] argument' do
      expect(replicator.id).to eq replication[:replication_id]
    end
  end

  describe '#bag_id' do
    it 'exists' do
      expect(replicator).to respond_to(:bag_id)
    end
    it 'works' do
      expect(replicator.bag_id).not_to be_nil
    end
    it 'returns a String' do
      expect(replicator.bag_id).to be_an String
    end
    it 'returns the replication[:bag] argument' do
      expect(replicator.bag_id).to eq replication[:bag]
    end
  end

  describe '#file' do
    let(:file) { replicator.file }
    it 'exists' do
      expect(replicator).to respond_to(:file)
    end
    it 'works' do
      expect(file).not_to be_nil
    end
    it 'returns a String' do
      expect(file).to be_an String
    end
    it 'returns the basename of the replication[:link]' do
      link = replication[:link]
      expect(file).to eq File.basename(link)
    end
  end

  describe '#to_h' do
    let(:hash) { replicator.to_h }
    it 'exists' do
      expect(replicator).to respond_to(:to_h)
    end
    it 'works' do
      expect(hash).not_to be_nil
    end
    it 'returns a Hash' do
      expect(hash).to be_an Hash
    end
    it 'returns the replication argument (when there are no updates)' do
      expect(hash).to eq replication
    end
  end

  describe "#admin_node" do
    let(:admin_node) { replicator.send(:admin_node) }
    it "works" do
      expect(admin_node).not_to be_nil
    end
    it "returns a DPN::Workers::Node" do
      expect(admin_node).to be_an DPN::Workers::Node
    end
    it "has the namespace of the replication[:from_node]" do
      expect(admin_node.namespace).to eq replication[:from_node]
    end
  end

  # let(:node) { replicator.admin_node }
  shared_examples 'updates_replication' do
    let(:client) { node.client }
    let(:update) { replicator.update(client) }
    let(:response) { double(DPN::Client::Response) }
    let(:replication_changed) do
      replication_changed = replication.dup
      replication_changed[:fixity_value] = 'abc123'
      replication_changed
    end
    context 'success' do
      before do
        allow(response).to receive(:success?).and_return(true)
        allow(response).to receive(:body).and_return(replicator.to_h)
        # expect(client).to receive(:update).and_return(response)
        expect(client).to receive(:update_replication).and_return(response)
      end
      it 'returns true when the node returns a successful response' do
        expect(update).to be true
      end
    end
    context 'when the replication has been modified locally' do
      # This mocks successful POST of modified replication data to node;
      # e.g., this simulates calculating the bagit fixity and POSTing it.
      before do
        replicator.instance_variable_set('@replication', OpenStruct.new(replication_changed))
        expect(replicator.to_h).not_to eq(replication)
        # simulate and HTTP update for the replication
        allow(response).to receive(:success?).and_return(true)
        allow(response).to receive(:body).and_return(replication_changed)
        expect(client).to receive(:update_replication).with(replication_changed).and_return(response)
      end
      it 'returns true when the update succeeds' do
        expect(update).to be true
      end
      it 'updates the instance data for the modified replication' do
        update
        expect(replicator.to_h).to eq(replication_changed)
      end
    end
    it 'raises RuntimeError when the node update request fails' do
      allow(response).to receive(:success?).and_return(false)
      allow(response).to receive(:body).and_return('error')
      allow(client).to receive(:update_replication).and_return(response)
      expect { update }.to raise_error(RuntimeError)
    end
  end

  describe '#update_admin' do
    let(:node) { replicator.admin_node }
    it_behaves_like 'updates_replication'
  end

  describe '#update_local' do
    # FIXME: assumes the replication already exists on the local node
    let(:node) { replicator.local_node }
    it_behaves_like 'updates_replication'
  end
end
