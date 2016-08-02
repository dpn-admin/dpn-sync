# -*- encoding: utf-8 -*-
require 'spec_helper'

describe SidekiqMonitor do
  let(:message) { subject.message }
  let(:settings) { SyncSettings.sidekiq }
  let(:size) { settings.acceptable_queue_size }
  let(:latency) { settings.acceptable_queue_latency }

  describe '#new' do
    it 'works' do
      expect(subject).not_to be_nil
    end
  end

  describe '#message' do
    it 'works' do
      expect(message).not_to be_nil
    end
    it 'is a String' do
      expect(message).to be_an String
    end
  end

  describe '#ok?' do
    it 'works' do
      result = subject.ok?
      expect(result).not_to be_nil
    end
    it 'is true when Sidekiq queue is small and fast' do
      queue = subject.send(:queue)
      expect(queue).to receive(:size).and_return(size - 1)
      expect(queue).to receive(:latency).and_return(latency - 1)
      result = subject.ok?
      expect(result).to be true
    end
    it 'is false when Sidekiq queue is large' do
      queue = subject.send(:queue)
      expect(queue).to receive(:size).and_return(size + 1)
      result = subject.ok?
      expect(result).to be false
    end
    it 'is false when Sidekiq queue is small, but slow' do
      queue = subject.send(:queue)
      expect(queue).to receive(:size).and_return(size - 1)
      expect(queue).to receive(:latency).and_return(latency + 1)
      result = subject.ok?
      expect(result).to be false
    end
  end
end
