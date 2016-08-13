# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::BagWorker do
  describe '#perform' do
    let(:replicator) { DPN::Workers::BagReplication.new replication }
    before do
      expect(DPN::Workers::BagReplication).to receive(:new).and_return(replicator)
    end
    it 'returns true for success' do
      expect(replicator).to receive(:replicate).and_return(true)
      result = subject.perform(replication)
      expect(result).to be true
    end
    it 'returns false for failure' do
      expect(replicator).to receive(:replicate).and_return(false)
      result = subject.perform(replication)
      expect(result).to be false
    end
    it 'raises exceptions for failure' do
      expect(replicator).to receive(:replicate).and_raise('failed')
      expect { subject.perform(replication) }.to raise_error(RuntimeError)
    end
  end
end
