# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::BagRsync do
  let(:settings) { SyncSettings.replication }

  let(:retrieve_file) { File.basename(retrieve_source) }
  let(:retrieve_source) { replication[:link] }
  let(:retrieve_target) do
    path = File.join(settings.staging_dir, 'test_rsync_retrieve')
    FileUtils.mkdir_p(path).first
  end
  let(:retrieve_target_file) { File.join(retrieve_target, retrieve_file) }

  let(:preserve_source) { retrieve_target_file }
  let(:preserve_target) do
    path = File.join(settings.storage_dir, 'test_rsync_preserve')
    FileUtils.mkdir_p(path).first
  end
  let(:preserve_target_file) { File.join(preserve_target, retrieve_file) }

  # Set defaults for retrieve
  let(:source) { retrieve_source }
  let(:target) { retrieve_target }
  let(:type) { 'retrieve' }
  let(:subject) { described_class.new source, target, type }

  shared_examples 'common_options' do
    it 'works' do
      expect(options).not_to be_nil
    end
    it 'returns a String' do
      expect(options).to be_an String
    end
    it 'contains the "--copy-dirlinks" option' do
      expect(options).to include '--copy-dirlinks'
    end
    it 'contains the "--copy-unsafe-links" option' do
      expect(options).to include '--copy-unsafe-links'
    end
    it 'contains the "--partial" option' do
      expect(options).to include '--partial'
    end
    it 'contains the "--quiet" option' do
      expect(options).to include '--quiet'
    end
  end

  context 'rsync mock behavior' do
    let(:rsync_result) { double }
    before do
      options = subject.send(:options)
      expect(Rsync).to receive(:run).with(source, target, options).and_yield(rsync_result)
    end
    it 'works' do
      expect(rsync_result).to receive(:success?).and_return(true)
      expect(subject).to be_an described_class
      expect(subject).to respond_to(:rsync)
      expect(subject.rsync).to be true
    end
    it 'raises RuntimeError when rsync fails' do
      expect(rsync_result).to receive(:success?).and_return(false)
      expect(rsync_result).to receive(:error).and_return('rsync error')
      expect { subject.rsync }.to raise_error(RuntimeError)
    end
  end

  context '#rsync "retrieve"' do
    it 'works' do
      expect(File.exist?(source)).to be true
      subject.rsync
      expect(File.exist?(retrieve_target_file)).to be true
    end
    describe '#options' do
      let(:options) { subject.send(:options) }
      it_behaves_like 'common_options'
      it 'contains the "--archive" option' do
        expect(options).to include '--archive'
      end
      it 'calls #ssh_option' do
        expect(subject).to receive(:ssh_option).and_call_original
        options
      end
    end
  end

  context '#rsync "preserve"' do
    # Override defaults for preserve
    let(:source) { preserve_source }
    let(:target) { preserve_target }
    let(:type) { 'preserve' }
    it 'works' do
      expect(File.exist?(source)).to be true
      expect(subject).to be_an described_class
      expect(subject).to respond_to(:rsync)
      subject.rsync
      expect(File.exist?(preserve_target_file)).to be true
    end
    describe '#options' do
      let(:options) { subject.send(:options) }
      it_behaves_like 'common_options'
      it 'contains the "--recursive" option' do
        expect(options).to include '--recursive'
      end
    end
  end

  context '#rsync "unknown"' do
    # Test failures for 'unknown' rsync type
    let(:type) { 'unknown' }
    describe '#options' do
      let(:options) { subject.send(:options) }
      it 'raises RuntimeError' do
        expect { options }.to raise_error(RuntimeError)
      end
    end
  end
end
