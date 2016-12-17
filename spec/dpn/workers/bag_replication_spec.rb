# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::BagReplication, :vcr do
  subject(:replicator) { described_class.new replication }

  it 'works' do
    expect(replicator).to be_an described_class
  end

  describe '#transfer' do
    it 'is an abstract method that raises NotImplementedError' do
      expect { replicator.transfer }.to raise_error(NotImplementedError)
    end
  end

  ##
  # PRIVATE

  it 'has a private accessor for bag storage paths' do
    expect(replicator.send(:paths)).to be_an DPN::Workers::BagPaths
  end

  it 'has a private accessor for a replication' do
    expect(replicator.send(:replication)).to be_an DPN::Workers::Replication
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
end
