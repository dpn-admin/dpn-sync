# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::BagReplication, :vcr do
  let(:settings) { SyncSettings.replication }
  let(:subject) { described_class.new replication }

  it 'works' do
    expect(subject).to be_an described_class
    expect(subject).to respond_to(:replicate)
    expect(subject).to respond_to(:id)
    expect(subject).to respond_to(:bag_id)
    expect(subject).to respond_to(:to_h)
  end

  describe '#id' do
    it 'works' do
      expect(subject.id).not_to be_nil
    end
    it 'returns a String' do
      expect(subject.id).to be_an String
    end
    it 'returns the replication[:replication_id] argument' do
      expect(subject.id).to eq replication[:replication_id]
    end
  end

  describe '#bag_id' do
    it 'works' do
      expect(subject.bag_id).not_to be_nil
    end
    it 'returns a String' do
      expect(subject.bag_id).to be_an String
    end
    it 'returns the replication[:bag] argument' do
      expect(subject.bag_id).to eq replication[:bag]
    end
  end

  describe '#replicate' do
    it "checks the replication status" do
      allow(subject).to receive(:retrieve)
      allow(subject).to receive(:preserve)
      expect(subject).to receive(:status).twice.and_return('requested')
      subject.replicate
    end

    shared_examples 'do_nothing' do
      it "returns a boolean result" do
        expect(subject.replicate).to be result
      end
      it "does not initiate replication tasks" do
        expect(subject).not_to receive(:retrieve)
        expect(subject).not_to receive(:preserve)
        expect(subject.replicate).to be result
      end
    end

    context "when the replication status is 'cancelled'" do
      let(:status) { 'cancelled' }
      let(:result) { false }
      before do
        expect(subject).to receive(:status).once.and_return(status)
      end
      it_behaves_like 'do_nothing'
    end

    context "when the replication status is 'rejected'" do
      let(:status) { 'rejected' }
      let(:result) { false }
      before do
        expect(subject).to receive(:status).once.and_return(status)
      end
      it_behaves_like 'do_nothing'
    end

    context "when the replication status is 'confirmed'" do
      let(:status) { 'confirmed' }
      let(:result) { true }
      before do
        expect(subject).to receive(:status).twice.and_return(status)
      end
      it_behaves_like 'do_nothing'
    end

    context "when the replication status is 'stored'" do
      let(:status) { 'stored' }
      let(:result) { true }
      before do
        expect(subject).to receive(:status).twice.and_return(status)
      end
      it_behaves_like 'do_nothing'
    end

    context "when the replication status is 'requested'" do
      it "performs replication tasks" do
        expect(subject).to receive(:retrieve).once.and_return(true)
        expect(subject).to receive(:preserve).once.and_return(true)
        expect(subject).to receive(:status).twice.and_return('requested')
        expect(subject.replicate).to be true
      end
    end
  end

  describe '#to_h' do
    it 'works' do
      expect(subject.to_h).not_to be_nil
    end
    it 'returns a Hash' do
      expect(subject.to_h).to be_an Hash
    end
    it 'returns the replication argument (when there are no updates)' do
      expect(subject.to_h).to eq replication
    end
  end

  ##
  # PRIVATE

  describe "#file" do
    let(:file) { subject.send(:file) }
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
    it "checks the replication status" do
      expect(subject).to receive(:status).twice.and_return('received')
      expect(subject).to receive(:preserve_rsync).and_return(true)
      expect(subject).to receive(:preserve_validate).and_return(true)
      expect(subject).to receive(:update_replication).with('stored').and_return(true)
      subject.send(:preserve)
    end

    context "when the replication status is 'stored'" do
      let(:status) { 'stored' }
      it 'returns true without doing any preservation tasks' do
        expect(subject).to receive(:status).once.and_return(status)
        expect(subject).not_to receive(:preserve_rsync)
        expect(subject).not_to receive(:preserve_validate)
        expect(subject).not_to receive(:update_replication)
        expect(subject.send(:preserve)).to be true
      end
    end

    context "when the replication status is 'received'" do
      let(:status) { 'received' }
      it "performs preservation tasks" do
        expect(subject).to receive(:status).twice.and_return(status)
        expect(subject).to receive(:preserve_rsync).and_return(true)
        expect(subject).to receive(:preserve_validate).and_return(true)
        expect(subject).to receive(:update_replication).and_return(true)
        expect(subject.send(:preserve)).to be true
      end
    end

    shared_examples 'preserve_raises_exception' do
      before do
        expect(subject).to receive(:status).exactly(3).times.and_return(status)
      end
      it "raises RuntimeError" do
        expect { subject.send(:preserve) }.to raise_error(RuntimeError)
      end
      it "does not initiate preservation tasks" do
        expect(subject).not_to receive(:preserve_rsync)
        expect(subject).not_to receive(:preserve_validate)
        expect(subject).not_to receive(:update_replication)
        expect { subject.send(:preserve) }.to raise_error(RuntimeError)
      end
    end

    context "when the replication status is 'cancelled'" do
      let(:status) { 'cancelled' }
      it_behaves_like 'preserve_raises_exception'
    end

    context "when the replication status is 'rejected'" do
      let(:status) { 'rejected' }
      it_behaves_like 'preserve_raises_exception'
    end

    context "when the replication status is 'confirmed'" do
      let(:status) { 'confirmed' }
      it_behaves_like 'preserve_raises_exception'
    end
  end

  shared_examples "bag_rsync_mocks" do
    let(:bagit) { double(DPN::Bagit::Bag) }
    let(:bag_sync) { double(DPN::Workers::BagRsync) }
    context 'rsync mock behavior' do
      before do
        allow(bagit).to receive(:location).and_return('a_bag_location')
        allow(subject).to receive(:bagit).and_return(bagit)
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
    let(:rsync) { subject.send(:preserve_rsync) }
    it_behaves_like 'bag_rsync_mocks'
    context 'rsync fixture behavior' do
      let(:bagit) { subject.send(:bagit) }
      let(:storage_path) { subject.send(:storage_path) }
      before do
        # perform retrieval tasks so a bag is available for preservation
        expect(subject.send(:retrieve_rsync)).to be true
        expect(subject.send(:retrieve_validate)).to be true
        expect(File.exist?(storage_path)).to be true
        expect(File.exist?(bagit.location)).to be true
      end
      it 'works' do
        bag_path_before = subject.send(:bagit_path)
        expect(File.exist?(bag_path_before)).to be true
        expect(subject.send(:preserve_rsync)).to be true
        expect(subject.send(:preserve_validate)).to be true
        bag_path_after = subject.send(:bagit_path)
        expect(File.exist?(bag_path_after)).to be true
        expect(bag_path_before).not_to eq bag_path_after
      end
    end
  end

  describe "#remote_node" do
    let(:remote_node) { subject.send(:remote_node) }
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
    it "checks the replication status" do
      expect(subject).to receive(:status).twice.and_return('requested')
      expect(subject).to receive(:retrieve_rsync).and_return(true)
      expect(subject).to receive(:retrieve_validate).and_return(true)
      expect(subject).to receive(:retrieve_fixity).and_return(true)
      expect(subject).to receive(:update_replication).with('received').and_return(true)
      subject.send(:retrieve)
    end
    shared_examples 'retrieval_is_done' do
      it 'returns true without doing any retrieval tasks' do
        expect(subject).to receive(:status).once.and_return(status)
        expect(subject).not_to receive(:retrieve_rsync)
        expect(subject).not_to receive(:retrieve_validate)
        expect(subject).not_to receive(:retrieve_fixity)
        expect(subject).not_to receive(:update_replication)
        expect(subject.send(:retrieve)).to be true
      end
    end
    context "when the replication status is 'confirmed'" do
      let(:status) { 'confirmed' }
      it_behaves_like 'retrieval_is_done'
    end
    context "when the replication status is 'received'" do
      let(:status) { 'received' }
      it_behaves_like 'retrieval_is_done'
    end
    context "when the replication status is 'stored'" do
      let(:status) { 'stored' }
      it_behaves_like 'retrieval_is_done'
    end
    shared_examples 'retrieve_raises_exception' do
      before do
        expect(subject).to receive(:status).exactly(3).times.and_return(status)
      end
      it "raises RuntimeError" do
        expect { subject.send(:retrieve) }.to raise_error(RuntimeError)
      end
      it "does not initiate retrieval tasks" do
        expect(subject).not_to receive(:retrieve_rsync)
        expect(subject).not_to receive(:retrieve_validate)
        expect(subject).not_to receive(:retrieve_fixity)
        expect(subject).not_to receive(:update_replication)
        expect { subject.send(:retrieve) }.to raise_error(RuntimeError)
      end
    end
    context "when the replication status is 'cancelled'" do
      let(:status) { 'cancelled' }
      it_behaves_like 'retrieve_raises_exception'
    end
    context "when the replication status is 'rejected'" do
      let(:status) { 'rejected' }
      it_behaves_like 'retrieve_raises_exception'
    end
  end

  describe "#retrieve_bagit" do
    let(:bagit) { subject.send(:bagit) }
    let(:bagit_id) { subject.bag_id }
    let(:bagit_path) { subject.send(:bagit_path) }
    let(:retrieve_path) { subject.send(:retrieve_path) }
    context 'unpack a .tar archive file' do
      before do
        # perform retrieval tasks so a .tar file is available
        expect(subject.send(:retrieve_rsync)).to be true
        expect(File.exist?(retrieve_path)).to be true
        expect(retrieve_path).to end_with '.tar'
      end
      it 'works' do
        expect(subject.send(:retrieve_bagit)).to be true
        expect(File.exist?(bagit_path)).to be true
        expect(bagit_path).to end_with(bagit_id + File::SEPARATOR)
      end
    end
    context 'create bagit bag from a bagit directory' do
      before do
        # perform retrieval and unpack a bagit .tar
        expect(subject.send(:retrieve_rsync)).to be true
        expect(File.exist?(retrieve_path)).to be true
        expect(retrieve_path).to end_with '.tar'
        expect(subject.send(:retrieve_bagit)).to be true
      end
      it 'works' do
        # mock the retrieve_path so it gets the unpacked bag instead of a .tar
        expect(subject).to receive(:retrieve_path).at_least(:once).and_return(bagit.location)
        retrieve_path = subject.send(:retrieve_path)
        expect(File.directory?(retrieve_path)).to be true
        expect(subject.send(:retrieve_bagit)).to be true
        expect(File.exist?(bagit_path)).to be true
        expect(bagit_path).to end_with(bagit_id + File::SEPARATOR)
        expect(subject.send(:validate)).to be true
      end
    end
    context 'cannot create a bagit bag from files that do not end with ".tar"' do
      before do
        # mock the retrieve_path so it returns a file name that can't work
        allow(subject).to receive(:retrieve_path).and_return('file.tar.gz')
        retrieve_path = subject.send(:retrieve_path)
        expect(File.directory?(retrieve_path)).to be false
      end
      it 'raises RuntimeError' do
        expect { subject.send(:retrieve_bagit) }.to raise_error(RuntimeError)
      end
    end
  end

  describe "#retrieve_fixity" do
    context 'calculates fixity on a bagit bag' do
      before do
        # perform retrieval tasks so a bagit bag is available
        expect(subject.send(:retrieve_rsync)).to be true
        expect(subject.send(:retrieve_bagit)).to be true
        expect(File.directory?(subject.send(:bagit_path))).to be true
      end
      it 'works when the remote node accepts the fixity_value' do
        expect(subject).to receive(:update_replication).and_return(true)
        expect(subject).to receive(:fixity_accept).twice.and_return(true)
        expect(subject.send(:retrieve_fixity)).to be true
      end
      it 'raises RuntimeError when the remote node rejects the fixity_value' do
        expect(subject).to receive(:update_replication).and_return(true)
        expect(subject).to receive(:fixity_accept).and_return(false)
        expect { subject.send(:retrieve_fixity) }.to raise_error(RuntimeError)
      end
    end
    it 'raises RuntimeError when a bagit bag is not available' do
      expect(subject).to receive(:bagit).and_return(nil)
      expect { subject.send(:retrieve_fixity) }.to raise_error(RuntimeError)
    end
  end

  describe "#retrieve_path" do
    let(:file) { subject.send(:file) }
    let(:retrieve_path) { subject.send(:retrieve_path) }
    let(:staging_path) { subject.send(:staging_path) }
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
    let(:rsync) { subject.send(:retrieve_rsync) }
    it_behaves_like 'bag_rsync_mocks'
    context 'rsync fixture behavior' do
      let(:link) { subject.send(:link) }
      let(:staging_path) { subject.send(:staging_path) }
      let(:retrieve_path) { subject.send(:retrieve_path) }
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
    let(:staging_path) { subject.send(:staging_path) }
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
    let(:storage_path) { subject.send(:storage_path) }
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
    let(:update) { subject.send(:update_replication) }
    let(:client) { subject.send(:remote_node).client }
    let(:response) { double(DPN::Client::Response) }
    context 'success' do
      before do
        allow(response).to receive(:success?).and_return(true)
        allow(response).to receive(:body).and_return(subject.to_h)
        expect(client).to receive(:update_replication).and_return(response)
      end
      it "works" do
        expect(update).not_to be_nil
      end
      it "returns true when the remote_node returns a successful response" do
        expect(update).to be true
      end
    end
    it "updates the replication 'status'" do
      status = 'stored'
      replication_changed = replication.dup
      replication_changed[:status] = status
      expect(replication_changed).not_to eq(replication)
      expect(response).to receive(:success?).and_return(true)
      expect(response).to receive(:body).and_return(replication_changed)
      expect(client).to receive(:update_replication).with(replication_changed).and_return(response)
      expect(subject.to_h).to eq(replication)
      expect(subject.send(:update_replication, status)).to be true
      expect(subject.to_h).to eq(replication_changed)
    end
    it "raises RuntimeError when the remote_node update request fails" do
      allow(response).to receive(:success?).and_return(false)
      allow(response).to receive(:body).and_return('error')
      expect(client).to receive(:update_replication).and_return(response)
      expect { update }.to raise_error(RuntimeError)
    end
  end

  describe "#validate" do
    let(:validate) { subject.send(:validate) }
    let(:bagit) { double(DPN::Bagit::Bag) }
    before do
      allow(subject).to receive(:bagit).and_return(bagit)
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
