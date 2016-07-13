# -*- encoding: utf-8 -*-
require 'spec_helper'

describe SidekiqMonitor do
  # TODO: auto-generated
  describe '#new' do
    it 'works' do
      result = described_class.new
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#message' do
    it 'works' do
      sidekiq_monitor = described_class.new
      result = sidekiq_monitor.message
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#status' do
    it 'works' do
      sidekiq_monitor = described_class.new
      result = sidekiq_monitor.status
      expect(result).not_to be_nil
    end
  end

  # TODO: auto-generated
  describe '#ok?' do
    it 'works' do
      sidekiq_monitor = described_class.new
      result = sidekiq_monitor.ok?
      expect(result).not_to be_nil
    end
  end
end
