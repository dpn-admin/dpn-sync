# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Monitor, :vcr do
  let(:message) { subject.message }
  let(:ok?) { subject.ok? }

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
      expect(ok?).not_to be_nil
    end
    it 'is true when nodes are alive' do
      nodes = subject.send(:nodes)
      expect(nodes).to receive(:all?).and_return(true)
      expect(ok?).to be true
    end
    it 'is false when nodes are not alive' do
      nodes = subject.send(:nodes)
      expect(nodes).to receive(:all?).and_return(false)
      expect(ok?).to be false
    end
  end
end
