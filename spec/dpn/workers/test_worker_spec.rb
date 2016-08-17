# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::TestWorker do
  describe '#perform' do
    it 'returns true for success' do
      result = subject.perform('msg')
      expect(result).to be true
    end
    it 'calls DPN::Workers::TestMessages.save' do
      expect(DPN::Workers::TestMessages).to receive(:save)
      subject.perform('msg')
    end
    context 'failures' do
      it 'raises exception given a "fail" message' do
        expect { subject.perform('fail') }.to raise_error(RuntimeError)
      end
      it 'raises exceptions on failure' do
        expect(REDIS).to receive(:lpush).and_raise('timeout')
        expect { subject.perform('msg') }.to raise_error(RuntimeError)
      end
    end
  end
end
