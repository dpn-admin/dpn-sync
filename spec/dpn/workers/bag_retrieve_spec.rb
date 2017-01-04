# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::BagRetrieve, :vcr do
  subject(:bag_retrieve) { described_class.new replication_reset }

  let(:replication_reset) do
    r = replication
    r[:stored] = false
    r[:store_requested] = false
    r[:cancelled] = false
    r
  end

  let(:repl) { bag_retrieve.send(:replication) }

  it 'works' do
    expect(bag_retrieve).to be_an described_class
    expect(bag_retrieve).to respond_to(:transfer)
  end

  describe '#transfer' do
    before do
      # Stub the retrieve method to prevent actual bag transfers, which
      # are tested in additional specs below.
      allow(bag_retrieve).to receive(:retrieve)
    end

    it 'checks the replication cancelled status' do
      expect(repl).to receive(:cancelled)
      bag_retrieve.transfer
    end

    it 'checks the replication store_requested status' do
      expect(repl).to receive(:cancelled).and_return(false)
      expect(repl).to receive(:store_requested)
      bag_retrieve.transfer
    end

    shared_examples 'do_nothing' do
      it 'returns a boolean result' do
        expect(bag_retrieve.transfer).to be result
      end
      it 'does not initiate replication tasks' do
        expect(bag_retrieve).not_to receive(:retrieve)
        bag_retrieve.transfer
      end
    end

    context 'returns false when the replication is cancelled' do
      before do
        allow(repl).to receive(:cancelled).and_return(true)
      end
      it_behaves_like 'do_nothing' do
        let(:result) { false }
      end
    end

    context 'returns true when the replication is already store_requested' do
      before do
        allow(repl).to receive(:cancelled).and_return(false)
        allow(repl).to receive(:store_requested).and_return(true)
      end
      it_behaves_like 'do_nothing' do
        let(:result) { true }
      end
    end

    context 'when the replication should be retrieved' do
      before do
        allow(repl).to receive(:cancelled).and_return(false)
        allow(repl).to receive(:store_requested).and_return(false)
      end
      it 'performs replication tasks' do
        expect(bag_retrieve).to receive(:retrieve)
        bag_retrieve.transfer
      end
    end
  end

  ##
  # PRIVATE

  describe '#retrieve' do
    before do
      allow(repl).to receive(:cancelled).and_return(false)
      allow(repl).to receive(:store_requested).and_return(false)
    end
    it 'does retrieval tasks' do
      expect(bag_retrieve).to receive(:retrieve_rsync).and_return(true)
      expect(bag_retrieve).to receive(:retrieve_validate).and_return(true)
      expect(bag_retrieve).to receive(:retrieve_fixity).and_return(true)
      expect(bag_retrieve).to receive(:retrieve_success?).and_return(true)
      expect(bag_retrieve.send(:retrieve)).to be true
    end
  end

  shared_examples 'bag_rsync_mocks' do
    let(:bag_sync) { double(DPN::Workers::BagRsync) }
    context 'rsync mock behavior' do
      before do
        allow(DPN::Workers::BagRsync).to receive(:new).and_return(bag_sync)
      end
      it 'works' do
        allow(bag_sync).to receive(:rsync).and_return(true)
        expect(rsync).to be true
      end
      it 'raises RuntimeError when rsync fails' do
        allow(bag_sync).to receive(:rsync).and_raise('rsync failed')
        expect { rsync }.to raise_error(RuntimeError)
      end
    end
  end

  describe '#retrieve_rsync' do
    let(:rsync) { bag_retrieve.send(:retrieve_rsync) }
    it_behaves_like 'bag_rsync_mocks'
    context 'rsync fixture behavior' do
      let(:bagit_staged) { bag_retrieve.send(:bagit) }
      it 'transfers a bag into staging' do
        expect(rsync).to be true
        expect(File.exist?(bagit_staged.location)).to be true
      end
    end
  end

  describe '#retrieve_validate' do
    let(:validate) { bag_retrieve.send(:retrieve_validate) }
    let(:bagit) { double(DPN::Bagit::Bag) }
    before do
      allow(bag_retrieve).to receive(:bagit).and_return(bagit)
    end
    it 'returns true when bagit.valid? is true' do
      allow(bagit).to receive(:valid?).and_return(true)
      expect(validate).to be true
    end
    it 'raises RuntimeError if bagit.valid? is false' do
      allow(bagit).to receive(:valid?).and_return(false)
      allow(bagit).to receive(:errors).and_return('error')
      expect { validate }.to raise_error(RuntimeError)
    end
  end

  describe "#retrieve_fixity" do
    let(:bagit) { bag_retrieve.send(:bagit) }
    let(:fixity) { bag_retrieve.send(:retrieve_fixity) }
    before do
      # rsync transfer creates a stage replication bag
      bag_retrieve.send(:retrieve_rsync)
    end
    it 'works' do
      expect(fixity).to eq 'e39a201a88bc3d7803a5e375d9752439d328c2e85b4f1ba70a6d984b6c5378bd'
    end
    it 'raises ArgumentError: Unknown algorithm' do
      allow(repl).to receive(:fixity_algorithm).and_return('md5sum')
      expect { fixity }.to raise_error(ArgumentError)
    end
  end

  describe '#retrieve_success?' do
    before do
      # rsync transfer creates a stage replication bag
      bag_retrieve.send(:retrieve_rsync)
      bag_retrieve.send(:retrieve_fixity)
    end
    it 'works when the admin node accepts the fixity_value' do
      expect(bag_retrieve.send(:retrieve_success?)).to be true
    end
    it 'raises RuntimeError when the admin node rejects the fixity_value' do
      allow(repl).to receive(:update).and_return(false)
      expect { bag_retrieve.send(:retrieve_success?) }.to raise_error(RuntimeError)
    end
  end

  describe '#retrieve_path' do
    let(:file) { repl.file }
    let(:retrieve_path) { bag_retrieve.send(:retrieve_path) }
    let(:staging_path) { bag_retrieve.send(:staging_path) }
    before do
      # rsync transfer creates a stage replication bag
      bag_retrieve.send(:retrieve_rsync)
    end
    it 'returns a String' do
      expect(retrieve_path).to be_an String
    end
    it 'creates a path beginning with the #staging_path' do
      expect(retrieve_path).to start_with(staging_path)
    end
    it 'creates a path ending in the #file' do
      expect(retrieve_path).to end_with(file)
    end
  end

  describe '#bagit' do
    let(:bagit) { bag_retrieve.send(:bagit) }
    let(:bagit_path) { bagit.location }
    let(:retrieve_path) { bag_retrieve.send(:retrieve_path) }
    before do
      # perform retrieval tasks so a .tar file is available
      expect(bag_retrieve.send(:retrieve_rsync)).to be true
      expect(File.exist?(retrieve_path)).to be true
      expect(retrieve_path).to end_with '.tar'
    end
    it 'can unpack a .tar archive file' do
      expect(bagit).to be_an DPN::Bagit::Bag
      expect(bagit_path).to end_with(bagit.uuid)
      expect(File.exist?(bagit_path)).to be true
    end
    it 'can unpack a .tar.gz archive file' do
      # move the retrieve_path file so it becomes a file that can't work
      tar_path = retrieve_path
      expect(File.exist?(tar_path)).to be true
      zip_path = retrieve_path + '.gz'
      system("gzip #{tar_path}")
      expect(File.exist?(tar_path)).to be false
      expect(File.exist?(zip_path)).to be true
      allow(bag_retrieve).to receive(:retrieve_path).and_return(zip_path)
      expect(bagit).to be_an DPN::Bagit::Bag
    end
    it 'can create a bagit bag from a bagit directory' do
      # Ensure a bagit is created, to unpack the .tar file
      expect(File.exist?(bagit_path)).to be true
      # mock the retrieve_path so it gets the unpacked bag instead of a .tar
      allow(bag_retrieve).to receive(:retrieve_path).and_return(bagit_path)
      # reset the memoized @bagit so that new calls will have to recreate it
      bag_retrieve.instance_variable_set('@bagit', nil)
      retrieve_path = bag_retrieve.send(:retrieve_path)
      expect(retrieve_path).not_to end_with '.tar'
      expect(File.directory?(retrieve_path)).to be true
      # now recreate the bagit from the directory
      expect(File.exist?(bagit_path)).to be true
      expect(bagit_path).to end_with(bagit.uuid)
      expect(bag_retrieve.send(:retrieve_validate)).to be true
    end
    it 'cannot create a bagit bag from files that do not end with ".tar"' do
      # zip the retrieve_path file so it becomes a file that can't work
      tar_path = retrieve_path
      expect(File.exist?(tar_path)).to be true
      zip_path = retrieve_path + '.zip'
      system("zip -q #{zip_path} #{tar_path}")
      expect(File.exist?(zip_path)).to be true
      allow(bag_retrieve).to receive(:retrieve_path).and_return(zip_path)
      expect { bag_retrieve.send(:bagit) }.to raise_error
    end
  end
end
