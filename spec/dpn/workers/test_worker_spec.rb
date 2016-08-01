# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::TestWorker do
  describe '#perform' do
    it 'returns true for success' do
      result = subject.perform('msg')
      expect(result).to be true
    end
    context 'failures' do
      it 'raises exceptions on failure' do
        expect(REDIS).to receive(:lpush).and_raise('timeout')
        expect { subject.perform('msg') }.to raise_error(RuntimeError)
      end
    end
  end
end
