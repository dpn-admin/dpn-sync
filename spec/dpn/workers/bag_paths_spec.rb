# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::BagPaths do
  let(:location) { 'tmp' }
  let(:settings) { SyncSettings.replication }
  let(:subject) { described_class.new }

  # Ignore :reek:UtilityFunction
  def cleanup_path(dir)
    path = File.join(dir, '*')
    FileUtils.rm_rf(Dir.glob(path), secure: true)
  end

  before do
    # Everything about replication depends on writable disk directories
    expect(File.writable?(settings.staging_dir)).to be true
    expect(File.writable?(settings.storage_dir)).to be true
  end

  after do
    cleanup_path settings.storage_dir
    cleanup_path settings.staging_dir
  end

  it 'works' do
    expect(subject).to be_an described_class
    expect(subject).to respond_to(:staging_dir)
    expect(subject).to respond_to(:storage_dir)
    expect(subject).to respond_to(:ssh_identity_file)
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

  context 'ssh_identity_file' do
    it 'is blank' do
      expect(settings).to receive(:ssh_identity_file).and_return(nil)
      expect { subject }.not_to raise_error
      expect(subject.ssh_identity_file).to be_nil
    end

    it 'returns SyncSettings.replication.ssh_identity_file' do
      ssh_file = 'ssh_identity_file'
      expect(settings).to receive(:ssh_identity_file).and_return(ssh_file)
      expect(subject.ssh_identity_file).to eq ssh_file
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
