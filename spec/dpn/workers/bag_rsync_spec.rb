# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::BagRsync, :vcr do
  subject(:bag_rsync) { described_class.new(source, target, type) }
  let(:settings) { SyncSettings.replication }

  let(:stage_file) { File.basename(stage_source) }
  let(:stage_source) { replication[:link] }
  let(:stage_target) do
    path = File.join(settings.staging_dir, 'test_rsync_stage')
    FileUtils.mkdir_p(path).first
  end
  let(:stage_target_file) { File.join(stage_target, stage_file) }

  let(:store_source) { stage_target_file }
  let(:store_target) do
    path = File.join(settings.storage_dir, 'test_rsync_store')
    FileUtils.mkdir_p(path).first
  end
  let(:store_target_file) { File.join(store_target, stage_file) }

  # Set defaults for stage
  let(:source) { stage_source }
  let(:target) { stage_target }
  let(:type) { 'stage' }

  shared_examples 'common_options' do
    it 'returns a String' do
      expect(options).to be_an String
    end
    it 'contains common rsync options' do
      expect(options).to include '--copy-dirlinks'
      expect(options).to include '--copy-unsafe-links'
      expect(options).to include '--partial'
      expect(options).to include '--quiet'
    end
  end

  context 'rsync mock behavior' do
    let(:rsync_result) { double }
    before do
      options = bag_rsync.send(:options)
      expect(Rsync).to receive(:run).with(source, target, options).and_yield(rsync_result)
    end
    it 'works' do
      expect(rsync_result).to receive(:success?).and_return(true)
      expect(bag_rsync).to be_an described_class
      expect(bag_rsync).to respond_to(:rsync)
      expect(bag_rsync.rsync).to be true
    end
    it 'raises RuntimeError when rsync fails' do
      expect(rsync_result).to receive(:success?).and_return(false)
      expect(rsync_result).to receive(:error).and_return('rsync error')
      expect { bag_rsync.rsync }.to raise_error(RuntimeError)
    end
  end

  context '#rsync "stage"' do
    it 'works' do
      expect(File.exist?(source)).to be true
      bag_rsync.rsync
      expect(File.exist?(stage_target_file)).to be true
    end
    describe "#options" do
      let(:options) { bag_rsync.send(:options) }
      it_behaves_like 'common_options'
      it 'contains the archive option' do
        expect(options).to include '--archive'
      end
      it 'calls #ssh_option' do
        expect(bag_rsync).to receive(:ssh_option).and_call_original
        options
      end
      it 'adds ssh command when ssh options are set' do
        ssh = SyncSettings.ssh
        ssh.user = 'ssh_user'
        ssh.identity_file = 'ssh_identity_file'
        expect(options).to match(/-e 'ssh.*#{ssh.user}.*#{ssh.identity_file}'/)
      end
    end
  end

  context '#rsync "store"' do
    # Override defaults for store
    let(:source) { store_source }
    let(:target) { store_target }
    let(:type) { 'store' }
    it 'works' do
      expect(File.exist?(source)).to be true
      expect(bag_rsync).to be_an described_class
      expect(bag_rsync).to respond_to(:rsync)
      bag_rsync.rsync
      expect(File.exist?(store_target_file)).to be true
    end
    describe "#options" do
      let(:options) { bag_rsync.send(:options) }
      it_behaves_like 'common_options'
      it 'contains the recursive option' do
        expect(options).to include '--recursive'
      end
    end
  end

  context '#rsync "unknown"' do
    # Test failures for 'unknown' rsync type
    let(:type) { 'unknown' }
    describe "#options" do
      let(:options) { bag_rsync.send(:options) }
      it 'raises RuntimeError' do
        expect { options }.to raise_error(RuntimeError)
      end
    end
  end
end
