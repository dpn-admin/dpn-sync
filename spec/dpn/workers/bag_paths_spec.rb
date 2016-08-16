# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::BagPaths do
  let(:location) { 'tmp' }
  let(:settings) { SyncSettings.replication }
  let(:subject) { described_class.new }

  before do
    # Everything about replication depends on writable disk directories
    expect(File.writable?(settings.staging_dir)).to be true
    expect(File.writable?(settings.storage_dir)).to be true
  end

  it 'works' do
    expect(subject).to be_an described_class
    expect(subject).to respond_to(:staging_dir)
    expect(subject).to respond_to(:storage_dir)
    expect(subject).to respond_to(:staging)
    expect(subject).to respond_to(:storage)
  end

  context 'staging_dir' do
    it 'is writable' do
      expect { subject }.not_to raise_error
    end

    it 'raises exception without write access' do
      expect(File).to receive(:writable?).with(settings.staging_dir).and_return(false)
      expect { subject }.to raise_error(RuntimeError)
    end
  end

  context 'storage_dir' do
    it 'is writable' do
      expect { subject }.not_to raise_error
    end

    it 'contains a Pairtree root path' do
      path = File.join(subject.storage_dir, 'pairtree_root')
      expect(File.exist?(path)).to be true
    end

    it 'raises exception without write access' do
      allow(File).to receive(:writable?).with(settings.staging_dir).and_return(true)
      expect(File).to receive(:writable?).with(settings.storage_dir).and_return(false)
      expect { subject }.to raise_error(RuntimeError)
    end
  end

  context 'staging' do
    it 'can create a writable "location" in staging_dir' do
      path = subject.staging(location)
      expect(path.start_with?(subject.staging_dir)).to be true
      expect(File.writable?(path)).to be true
    end
  end

  context 'storage' do
    it 'can create a writable "location" in storage_dir' do
      path = subject.storage(location)
      expect(path.start_with?(subject.storage_dir)).to be true
      expect(File.writable?(path)).to be true
    end
  end
end
