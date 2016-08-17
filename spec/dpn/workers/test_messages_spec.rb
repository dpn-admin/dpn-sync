# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::TestMessages do
  let(:redis_key) { SyncSettings.sidekiq.test_message_store }

  after do
    described_class.clear
  end

  describe '#all' do
    it 'works' do
      result = described_class.all
      expect(result).to be_an Array
      expect(result).to be_empty
    end
    it 'retrieves from the Redis list for SyncSettings.sidekiq.test_message_store' do
      msg = 'get this'
      described_class.save msg
      expect(REDIS).to receive(:lrange).with(redis_key, 0, -1).and_call_original
      expect(described_class.all).to include(/#{msg}/)
    end
  end

  describe '#clear' do
    it 'works' do
      result = described_class.clear
      expect(result).to be true
    end
    it 'clears the Redis list for SyncSettings.sidekiq.test_message_store' do
      expect(REDIS).to receive(:del).with(redis_key).twice.and_call_original
      described_class.clear
    end
  end

  describe '#save' do
    let(:msg) { 'rspec msg' }
    it 'works' do
      result = described_class.save(msg)
      expect(result).to be true
    end
    it 'pushes to the Redis list for SyncSettings.sidekiq.test_message_store' do
      expect(REDIS).to receive(:lpush).with(redis_key, /#{msg}/i).and_return(1)
      described_class.save msg
    end
  end
end
