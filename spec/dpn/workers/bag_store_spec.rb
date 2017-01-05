# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::BagStore, :vcr do
  subject(:bag_store) { described_class.new replication_reset }

  let(:replication_reset) do
    r = replication
    r[:stored] = false
    r[:store_requested] = false
    r[:cancelled] = false
    r
  end

  let(:repl) { bag_store.send(:replication) }

  let(:bagit_staged) do
    # perform staging tasks so a bag is available for storage
    retrieve = DPN::Workers::BagRetrieve.new(replication_reset)
    retrieve.send(:bagit) if retrieve.transfer
  end
  let(:bagit_stored) { bag_store.send(:bagit) }

  it 'works' do
    expect(bag_store).to be_an described_class
    expect(bag_store).to respond_to(:transfer)
  end

  describe '#transfer' do
    before do
      # Stub the store method to prevent actual bag transfers, which
      # are tested in additional specs below.
      allow(bag_store).to receive(:store)
    end

    it 'checks if the replication was stored' do
      expect(repl).to receive(:stored)
      bag_store.transfer
    end

    it 'checks if the replication was cancelled' do
      expect(repl).to receive(:stored).and_return(false)
      expect(repl).to receive(:cancelled)
      bag_store.transfer
    end

    it 'checks if the replication store is requested' do
      expect(repl).to receive(:stored).and_return(false)
      expect(repl).to receive(:cancelled).and_return(false)
      expect(repl).to receive(:store_requested)
      bag_store.transfer
    end

    shared_examples 'do_nothing' do
      it 'returns a boolean result' do
        expect(bag_store.transfer).to be result
      end
      it 'does not initiate replication tasks' do
        expect(bag_store).not_to receive(:store)
        bag_store.transfer
      end
    end

    context 'when the replication is stored' do
      before do
        allow(repl).to receive(:stored).and_return(true)
      end
      it_behaves_like 'do_nothing' do
        let(:result) { true }
      end
    end

    context 'when the replication is cancelled' do
      before do
        allow(repl).to receive(:stored).and_return(false)
        allow(repl).to receive(:cancelled).and_return(true)
      end
      it_behaves_like 'do_nothing' do
        let(:result) { false }
      end
    end

    context 'when the replication store is not requested' do
      before do
        allow(repl).to receive(:stored).and_return(false)
        allow(repl).to receive(:cancelled).and_return(false)
        allow(repl).to receive(:store_requested).and_return(false)
      end
      it_behaves_like 'do_nothing' do
        let(:result) { false }
      end
    end

    context 'when the replication should be stored' do
      before do
        allow(repl).to receive(:stored).and_return(false)
        allow(repl).to receive(:cancelled).and_return(false)
        allow(repl).to receive(:store_requested).and_return(true)
      end
      it 'performs replication tasks' do
        expect(bag_store).to receive(:store)
        bag_store.transfer
      end
    end
  end

  ##
  # PRIVATE

  describe '#store' do
    before do
      allow(repl).to receive(:stored).and_return(false)
      allow(repl).to receive(:cancelled).and_return(false)
      allow(repl).to receive(:store_requested).and_return(true)
    end
    it 'does storage tasks' do
      expect(bag_store).to receive(:preserve_rsync).and_return(true)
      expect(bag_store).to receive(:preserve_validate).and_return(true)
      expect(bag_store).to receive(:update_replication).and_return(true)
      expect(bag_store).to receive(:staging_cleanup).and_return(true)
      expect(bag_store.send(:store)).to be true
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

  describe "#preserve_rsync" do
    let(:rsync) { bag_store.send(:preserve_rsync) }
    let(:validate) { bag_store.send(:preserve_validate) }
    it_behaves_like 'bag_rsync_mocks'
    context 'rsync fixture behavior' do
      before do
        bag_is_staged = File.exist?(bagit_staged.location)
        expect(bag_is_staged).to be true
      end
      it 'transfers a bag into storage' do
        expect(rsync).to be true
        expect(validate).to be true
        expect(File.exist?(bagit_stored.location)).to be true
      end
    end
  end

  describe "#preserve_validate" do
    let(:validate) { bag_store.send(:preserve_validate) }
    let(:bagit) { double(DPN::Bagit::Bag) }
    before do
      allow(bag_store).to receive(:bagit).and_return(bagit)
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

  describe '#staging_cleanup' do
    let(:cleanup) { bag_store.send(:staging_cleanup) }
    let(:bagit) {  bag_store.send(:bagit) }
    it 'checks bagit.valid?' do
      expect(bagit).to receive(:valid?)
      cleanup
    end
    it 'returns false when bagit.valid? is false' do
      allow(bagit).to receive(:valid?).and_return(false)
      expect(cleanup).to be false
    end
    it 'will cleanup staging path when bagit.valid? is true' do
      expect(File.exist?(bagit_staged.location)).to be true
      expect(bag_store.send(:preserve_rsync)).to be true
      expect(bag_store.send(:preserve_validate)).to be true
      expect(FileUtils).to receive(:rm_r).and_call_original
      expect(cleanup).to be true
      expect(File.exist?(bagit_staged.location)).to be false
    end
  end

  describe '#update_replication' do
    let(:update) { bag_store.send(:update_replication) }
    let(:admin_client) { repl.admin_client }
    let(:local_client) { repl.local_client }
    let(:response_success) do
      resp = double(DPN::Client::Response)
      allow(resp).to receive(:success?).and_return(true)
      allow(resp).to receive(:body).and_return(repl.to_h)
      resp
    end
    let(:response_failure) do
      resp = double(DPN::Client::Response)
      allow(resp).to receive(:success?).and_return(false)
      allow(resp).to receive(:body).and_return('update_replication error')
      resp
    end
    it 'returns true when the updates are successful' do
      expect(repl).to receive(:stored=).with(true)
      expect(admin_client).to receive(:update_replication).and_return(response_success)
      expect(local_client).to receive(:update_replication).and_return(response_success)
      expect(update).to be true
    end
    context 'failure' do
      it 'raises RuntimeError when the admin_node update fails' do
        allow(admin_client).to receive(:update_replication).and_return(response_failure)
        allow(local_client).to receive(:update_replication).and_return(response_success)
        expect { update }.to raise_error(RuntimeError)
      end
      it 'raises RuntimeError when the local_node update fails' do
        allow(admin_client).to receive(:update_replication).and_return(response_success)
        allow(local_client).to receive(:update_replication).and_return(response_failure)
        expect { update }.to raise_error(RuntimeError)
      end
    end
  end
end
