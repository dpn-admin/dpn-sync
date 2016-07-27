# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::SyncWorker do
  describe '#perform' do
    before do
      expect(DPN::Workers).to receive(:nodes).and_return(nodes)
    end
    let(:sync_bags) { 'DPN::Workers::SyncBags' }
    it 'returns true for success' do
      expect(nodes).to receive(:sync).with(sync_bags).and_return(true)
      result = subject.perform(sync_bags)
      expect(result).to be true
    end
    it 'returns false for failure' do
      expect(nodes).to receive(:sync).with(sync_bags).and_return(false)
      result = subject.perform(sync_bags)
      expect(result).to be false
    end
    it 'logs exceptions for failure' do
      expect(nodes).to receive(:sync).with(sync_bags).and_raise('failed')
      expect(subject.logger).to receive(:error)
      result = subject.perform(sync_bags)
      expect(result).to be false
    end
  end
end
