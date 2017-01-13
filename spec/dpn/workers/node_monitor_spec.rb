# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::NodeMonitor, :vcr do
  subject(:node_monitor) { described_class.new remote_node }
  let(:message) { node_monitor.message }
  let(:node) { node_monitor.send(:node) }
  let(:ok?) { node_monitor.ok? }

  describe '#new' do
    it 'works' do
      expect(node_monitor).not_to be_nil
    end
  end

  describe '#message' do
    it 'is a String' do
      expect(message).to be_an String
    end
  end

  describe '#ok?' do
    it 'is true when node is alive' do
      expect(node).to receive(:alive?).and_return(true)
      expect(ok?).to be true
    end
    it 'is false when node is not alive' do
      expect(node).to receive(:alive?).and_return(false)
      expect(ok?).to be false
    end
  end
end
