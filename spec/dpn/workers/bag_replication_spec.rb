# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::BagReplication, :vcr do
  let(:settings) { SyncSettings.replication }
  let(:replicator) { described_class.new replication }

  it 'works' do
    expect(replicator).to be_an described_class
    expect(replicator).to respond_to(:replicate)
    expect(replicator).to respond_to(:id)
    expect(replicator).to respond_to(:bag_id)
    expect(replicator).to respond_to(:to_h)
  end

  it 'has private accessors for replication data' do
    replication.keys do |key|
      expect { replicator.send(key) }.not_to raise_error
      expect(replicator.send(key)).to eq(replication[key])
    end
  end

  describe '#id' do
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

  describe '#replicate' do
    it "checks if the replication was cancelled" do
      expect(replicator).to receive(:retrieve)
      expect(replicator).to receive(:cancelled).and_return(false)
      replicator.replicate
    end

    shared_examples 'do_nothing' do
      it "returns a boolean result" do
        expect(replicator.replicate).to be result
      end
      it "does not initiate replication tasks" do
        expect(replicator).not_to receive(:retrieve)
        expect(replicator).not_to receive(:preserve)
        expect(replicator.replicate).to be result
      end
    end

    context "when the replication is cancelled" do
      let(:result) { false }
      before do
        expect(replicator).to receive(:cancelled).and_return(true)
      end
      it_behaves_like 'do_nothing'
    end

    context "when the replication is 'stored'" do
      let(:result) { true }
      before do
        expect(replicator).to receive(:stored).and_return(true)
      end
      it_behaves_like 'do_nothing'
    end

    context "when the replication is not 'cancelled' or 'stored'" do
      it 'performs replication tasks' do
        expect(replicator).to receive(:retrieve).once.and_return(true)
        expect(replicator).to receive(:preserve).once.and_return(true)
        expect(replicator).to receive(:cancelled).and_return(false)
        expect(replicator).to receive(:stored).and_return(false)
        expect(replicator.replicate).to be true
      end
    end
  end

  describe '#to_h' do
    it 'works' do
      expect(replicator.to_h).not_to be_nil
    end
    it 'returns a Hash' do
      expect(replicator.to_h).to be_an Hash
    end
    it 'returns the replication argument (when there are no updates)' do
      expect(replicator.to_h).to eq replication
    end
  end

  ##
  # PRIVATE

  describe "#file" do
    let(:file) { replicator.send(:file) }
    it "works" do
      expect(file).not_to be_nil
    end
    it "returns a String" do
      expect(file).to be_an String
    end
    it "returns the basename of the replication[:link]" do
      link = replication[:link]
      expect(file).to eq File.basename(link)
    end
  end

  describe '#preserve' do
    it 'does preservation tasks when !cancelled && !stored && store_requested' do
      expect(replicator).to receive(:cancelled).and_return(false)
      expect(replicator).to receive(:stored).and_return(false)
      expect(replicator).to receive(:store_requested).and_return(true)
      expect(replicator).to receive(:preserve_rsync).and_return(true)
      expect(replicator).to receive(:preserve_validate).and_return(true)
      expect(replicator).to receive(:update_replication).and_return(true)
      replicator.send(:preserve)
    end

    context "when the replication is 'stored'" do
      it 'returns true without doing any preservation tasks' do
        expect(replicator).to receive(:stored).and_return(true)
        expect(replicator).not_to receive(:preserve_rsync)
        expect(replicator).not_to receive(:preserve_validate)
        expect(replicator).not_to receive(:update_replication)
        expect(replicator.send(:preserve)).to be true
      end
    end

    context "when the replication is 'cancelled'" do
      before do
        expect(replicator).to receive(:cancelled).and_return(true)
      end
      it 'returns false' do
        expect(replicator.send(:preserve)).to be false
      end
      it 'does not initiate preservation tasks' do
        expect(replicator).not_to receive(:preserve_rsync)
        expect(replicator).not_to receive(:preserve_validate)
        expect(replicator).not_to receive(:update_replication)
        expect(replicator.send(:preserve)).to be false
      end
    end
  end

  shared_examples 'bag_rsync_mocks' do
    let(:bagit) { double(DPN::Bagit::Bag) }
    let(:bag_sync) { double(DPN::Workers::BagRsync) }
    context 'rsync mock behavior' do
      before do
        allow(bagit).to receive(:location).and_return('a_bag_location')
        allow(replicator).to receive(:bagit).and_return(bagit)
        expect(DPN::Workers::BagRsync).to receive(:new).and_return(bag_sync)
      end
      it 'works' do
        expect(bag_sync).to receive(:rsync).and_return(true)
        expect(rsync).to be true
      end
      it 'raises RuntimeError when rsync fails' do
        expect(bag_sync).to receive(:rsync).and_raise('rsync failed')
        expect { rsync }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#preserve_rsync" do
    let(:rsync) { replicator.send(:preserve_rsync) }
    it_behaves_like 'bag_rsync_mocks'
    context 'rsync fixture behavior' do
      let(:bagit) { replicator.send(:bagit) }
      let(:storage_path) { replicator.send(:storage_path) }
      before do
        # perform retrieval tasks so a bag is available for preservation
        expect(replicator.send(:retrieve_rsync)).to be true
        expect(replicator.send(:retrieve_validate)).to be true
        expect(File.exist?(storage_path)).to be true
        expect(File.exist?(bagit.location)).to be true
      end
      it 'works' do
        bag_path_before = replicator.send(:bagit_path)
        expect(File.exist?(bag_path_before)).to be true
        expect(replicator.send(:preserve_rsync)).to be true
        expect(replicator.send(:preserve_validate)).to be true
        bag_path_after = replicator.send(:bagit_path)
        expect(File.exist?(bag_path_after)).to be true
        expect(bag_path_before).not_to eq bag_path_after
      end
    end
  end

  describe "#remote_node" do
    let(:remote_node) { replicator.send(:remote_node) }
    it "works" do
      expect(remote_node).not_to be_nil
    end
    it "returns a DPN::Workers::Node" do
      expect(remote_node).to be_an DPN::Workers::Node
    end
    it "has the namespace of the replication[:from_node]" do
      expect(remote_node.namespace).to eq replication[:from_node]
    end
  end

  describe '#retrieve' do
    it 'returns true after all retrieval tasks succeed' do
      allow(replicator).to receive(:retrieve_rsync).and_return(true)
      allow(replicator).to receive(:retrieve_validate).and_return(true)
      allow(replicator).to receive(:retrieve_fixity).and_return(true)
      allow(replicator).to receive(:retrieve_success?).and_return(true)
      expect(replicator.send(:retrieve)).to be true
    end
    it 'returns false when retrieve_rsync fails' do
      allow(replicator).to receive(:retrieve_rsync).and_return(false)
      expect(replicator).not_to receive(:retrieve_validate)
      expect(replicator).not_to receive(:retrieve_fixity)
      expect(replicator).not_to receive(:retrieve_success?)
      expect(replicator.send(:retrieve)).to be false
    end
    it 'returns false when retrieve_validate fails' do
      allow(replicator).to receive(:retrieve_rsync).and_return(true)
      allow(replicator).to receive(:retrieve_validate).and_return(false)
      expect(replicator).not_to receive(:retrieve_fixity)
      expect(replicator).not_to receive(:retrieve_success?)
      expect(replicator.send(:retrieve)).to be false
    end
    it 'returns false when retrieve_fixity fails' do
      allow(replicator).to receive(:retrieve_rsync).and_return(true)
      allow(replicator).to receive(:retrieve_validate).and_return(true)
      allow(replicator).to receive(:retrieve_fixity).and_return(false)
      expect(replicator).not_to receive(:retrieve_success?)
      expect(replicator.send(:retrieve)).to be false
    end
    it 'returns false when retrieve_success? fails' do
      allow(replicator).to receive(:retrieve_rsync).and_return(true)
      allow(replicator).to receive(:retrieve_validate).and_return(true)
      allow(replicator).to receive(:retrieve_fixity).and_return(true)
      allow(replicator).to receive(:retrieve_success?).and_return(false)
      expect(replicator.send(:retrieve)).to be false
    end
    it 'allows exceptions from any retrieve processes' do
      allow(replicator).to receive(:retrieve_rsync).and_raise('failed rsync')
      expect(replicator).not_to receive(:retrieve_validate)
      expect(replicator).not_to receive(:retrieve_fixity)
      expect(replicator).not_to receive(:retrieve_success?)
      expect { replicator.send(:retrieve) }.to raise_error(RuntimeError)
    end
  end

  describe "#retrieve_bagit" do
    let(:bagit) { replicator.send(:bagit) }
    let(:bagit_id) { replicator.bag_id }
    let(:bagit_path) { replicator.send(:bagit_path) }
    let(:retrieve_path) { replicator.send(:retrieve_path) }
    context 'unpack a .tar archive file' do
      before do
        # perform retrieval tasks so a .tar file is available
        expect(replicator.send(:retrieve_rsync)).to be true
        expect(File.exist?(retrieve_path)).to be true
        expect(retrieve_path).to end_with '.tar'
      end
      it 'works' do
        expect(replicator.send(:retrieve_bagit)).to be true
        expect(File.exist?(bagit_path)).to be true
        expect(bagit_path).to end_with(bagit_id + File::SEPARATOR)
      end
    end
    context 'create bagit bag from a bagit directory' do
      before do
        # perform retrieval and unpack a bagit .tar
        expect(replicator.send(:retrieve_rsync)).to be true
        expect(File.exist?(retrieve_path)).to be true
        expect(retrieve_path).to end_with '.tar'
        expect(replicator.send(:retrieve_bagit)).to be true
      end
      it 'works' do
        # mock the retrieve_path so it gets the unpacked bag instead of a .tar
        expect(replicator).to receive(:retrieve_path).at_least(:once).and_return(bagit.location)
        retrieve_path = replicator.send(:retrieve_path)
        expect(File.directory?(retrieve_path)).to be true
        expect(replicator.send(:retrieve_bagit)).to be true
        expect(File.exist?(bagit_path)).to be true
        expect(bagit_path).to end_with(bagit_id + File::SEPARATOR)
        expect(replicator.send(:validate)).to be true
      end
    end
    context 'cannot create a bagit bag from files that do not end with ".tar"' do
      before do
        # mock the retrieve_path so it returns a file name that can't work
        allow(replicator).to receive(:retrieve_path).and_return('file.tar.gz')
        retrieve_path = replicator.send(:retrieve_path)
        expect(File.directory?(retrieve_path)).to be false
      end
      it 'raises RuntimeError' do
        expect { replicator.send(:retrieve_bagit) }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#retrieve_success?" do
    context 'calculates fixity on a bagit bag' do
      before do
        # perform retrieval tasks so a bagit bag has a fixity value
        expect(replicator.send(:retrieve_rsync)).to be true
        expect(replicator.send(:retrieve_bagit)).to be true
        expect(File.directory?(replicator.send(:bagit_path))).to be true
        expect(replicator.send(:retrieve_fixity)).to eq 'cd9c918c4ca76842febfc70ed27873c70a7e98f436bd2061e4b714092ffcae5b'
      end
      it 'works when the remote node accepts the fixity_value' do
        expect(replicator).to receive(:update_replication).and_return(true)
        expect(replicator).to receive(:store_requested).twice.and_return(true)
        expect(replicator.send(:retrieve_success?)).to be true
      end
      it 'raises RuntimeError when the remote node rejects the fixity_value' do
        expect(replicator).to receive(:update_replication).and_return(true)
        expect(replicator).to receive(:store_requested).and_return(false)
        expect { replicator.send(:retrieve_success?) }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#retrieve_fixity" do
    context 'calculates fixity on a bagit bag' do
      before do
        # perform retrieval tasks so a bagit bag is available
        expect(replicator.send(:retrieve_rsync)).to be true
        expect(replicator.send(:retrieve_bagit)).to be true
        expect(File.directory?(replicator.send(:bagit_path))).to be true
      end
      it 'works' do
        expect(replicator.send(:retrieve_fixity)).to eq 'cd9c918c4ca76842febfc70ed27873c70a7e98f436bd2061e4b714092ffcae5b'
      end
    end
    it 'raises RuntimeError when a bagit bag is not available' do
      expect(replicator).to receive(:bagit).and_return(nil)
      expect { replicator.send(:retrieve_fixity) }.to raise_error(RuntimeError)
    end
  end

  describe "#retrieve_path" do
    let(:file) { replicator.send(:file) }
    let(:retrieve_path) { replicator.send(:retrieve_path) }
    let(:staging_path) { replicator.send(:staging_path) }
    before do
      # assume an rsync transfer has already completed successfully
      allow(File).to receive(:exist?).and_return(true)
    end
    it "works" do
      expect(retrieve_path).not_to be_nil
    end
    it "returns a String" do
      expect(retrieve_path).to be_an String
    end
    it "creates a path beginning with the #staging_path" do
      expect(retrieve_path).to start_with(staging_path)
    end
    it "creates a path ending in the #file" do
      expect(retrieve_path).to end_with(file)
    end
  end

  describe "#retrieve_rsync" do
    let(:rsync) { replicator.send(:retrieve_rsync) }
    it_behaves_like 'bag_rsync_mocks'
    context 'rsync fixture behavior' do
      let(:link) { replicator.send(:link) }
      let(:staging_path) { replicator.send(:staging_path) }
      let(:retrieve_path) { replicator.send(:retrieve_path) }
      before do
        expect(File.exist?(link)).to be true
        expect(File.exist?(staging_path)).to be true
      end
      it 'works' do
        expect(rsync).to be true
        expect(File.exist?(retrieve_path)).to be true
      end
    end
  end

  describe "#staging_path" do
    let(:staging_path) { replicator.send(:staging_path) }
    it "works" do
      expect(staging_path).not_to be_nil
    end
    it "returns a String" do
      expect(staging_path).to be_an String
    end
    it "creates a path ending in the replication[:replication_id]" do
      id = replication[:replication_id]
      expect(staging_path).to end_with(id)
    end
  end

  describe "#storage_path" do
    let(:storage_path) { replicator.send(:storage_path) }
    it "works" do
      expect(storage_path).not_to be_nil
    end
    it "returns a String" do
      expect(storage_path).to be_an String
    end
    it "creates a path ending in the replication[:bag]" do
      id = replication[:bag]
      expect(storage_path).to end_with(id)
    end
  end

  describe "#update_replication" do
    let(:update) { replicator.send(:update_replication) }
    let(:client) { replicator.send(:remote_node).client }
    let(:response) { double(DPN::Client::Response) }
    context 'success' do
      before do
        allow(response).to receive(:success?).and_return(true)
        allow(response).to receive(:body).and_return(replicator.to_h)
        expect(client).to receive(:update_replication).and_return(response)
      end
      it 'works' do
        expect(update).not_to be_nil
      end
      it 'returns true when the remote_node returns a successful response' do
        expect(update).to be true
      end
    end
    it 'updates the replication data' do
      # simulate calculating the bagit fixity
      replication_changed = replication.dup
      replication_changed[:fixity_value] = 'abc123'
      replicator.instance_variable_set('@_replication', OpenStruct.new(replication_changed))
      expect(replicator.to_h).not_to eq(replication)
      # simulate and HTTP update for the replication
      expect(response).to receive(:success?).and_return(true)
      expect(response).to receive(:body).and_return(replication_changed)
      expect(client).to receive(:update_replication).with(replication_changed).and_return(response)
      expect(replicator.send(:update_replication)).to be true
      expect(replicator.to_h).to eq(replication_changed)
    end
    it "raises RuntimeError when the remote_node update request fails" do
      allow(response).to receive(:success?).and_return(false)
      allow(response).to receive(:body).and_return('error')
      expect(client).to receive(:update_replication).and_return(response)
      expect { update }.to raise_error(RuntimeError)
    end
  end

  describe "#validate" do
    let(:validate) { replicator.send(:validate) }
    let(:bagit) { double(DPN::Bagit::Bag) }
    before do
      allow(replicator).to receive(:bagit).and_return(bagit)
    end
    it "works" do
      expect(bagit).to receive(:valid?).and_return(true)
      expect(validate).not_to be_nil
    end
    it "returns true when bagit.valid? is true" do
      expect(bagit).to receive(:valid?).and_return(true)
      expect(validate).to be true
    end
    it "raises RuntimeError if #bagit.valid? is false" do
      expect(bagit).to receive(:valid?).and_return(false)
      expect(bagit).to receive(:errors).and_return('error')
      expect { validate }.to raise_error(RuntimeError)
    end
  end
end
