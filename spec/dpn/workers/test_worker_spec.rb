# -*- encoding: utf-8 -*-

require 'spec_helper'

describe DPN::Workers::TestWorker do
  describe '#perform' do
    it 'returns true for success' do
      result = subject.perform('msg')
      expect(result).to be true
    end
    it 'returns false for failure' do
      expect(REDIS).to receive(:lpush).and_raise('timeout')
      result = subject.perform('msg')
      expect(result).to be false
    end
    it 'logs exceptions for failure' do
      expect(REDIS).to receive(:lpush).and_raise('timeout')
      expect(subject.logger).to receive(:error)
      subject.perform('msg')
    end
  end
end
