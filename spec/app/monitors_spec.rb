# -*- encoding: utf-8 -*-
require 'spec_helper'

describe Monitors, :vcr do
  let(:messages) { subject.messages }
  let(:monitors) { subject.send(:monitors) }
  let(:status) { subject.status }

  describe '#new' do
    it 'works' do
      expect(subject).not_to be_nil
    end
    it 'is a Monitors' do
      expect(subject).to be_an described_class
    end
  end

  describe '#messages' do
    it 'works' do
      expect(messages).not_to be_nil
    end
    it 'is a String' do
      expect(messages).to be_an String
    end
  end

  describe '#status' do
    it 'works' do
      expect(status).not_to be_nil
    end
    it 'is an Integer' do
      expect(status).to be_an Integer
    end
    it 'is 200 on success' do
      expect(monitors).to receive(:all?).and_return(true)
      expect(status).to eq 200
    end
    it 'is 500 on failure' do
      expect(monitors).to receive(:all?).and_return(false)
      expect(status).to eq 500
    end
  end
end
