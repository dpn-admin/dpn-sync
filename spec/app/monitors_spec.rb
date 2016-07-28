# -*- encoding: utf-8 -*-
require 'spec_helper'

describe Monitors do
  describe '#new' do
    it 'works' do
      expect(subject).not_to be_nil
    end
    it 'is a Monitors' do
      expect(subject).to be_an described_class
    end
  end

  context 'success' do
    describe '#messages' do
      before do
        monitors = subject.send(:monitors)
        monitors.each do |monitor|
          expect(monitor).to receive(:message).and_return('OK')
        end
      end
      it 'works' do
        expect(subject.messages).not_to be_nil
      end
      it 'is a String' do
        expect(subject.messages).to be_an String
      end
      it 'contains "OK"' do
        expect(subject.messages).to include 'OK'
      end
    end

    describe '#status' do
      before do
        monitors = subject.send(:monitors)
        monitors.each do |monitor|
          expect(monitor).to receive(:ok?).and_return(true)
        end
      end
      it 'works' do
        expect(subject.status).not_to be_nil
      end
      it 'is an Integer' do
        expect(subject.status).to be_an Integer
      end
      it 'is 200 on success' do
        expect(subject.status).to eq 200
      end
    end
  end

  context 'failure' do
    describe '#messages' do
      before do
        monitors = subject.send(:monitors)
        monitors.each do |monitor|
          expect(monitor).to receive(:message).and_return('WARNING')
        end
      end
      it 'contains "WARNING"' do
        expect(subject.messages).to include 'WARNING'
      end
    end

    describe '#status' do
      before do
        monitor = subject.send(:monitors).first
        expect(monitor).to receive(:ok?).and_return(false)
      end
      it 'is 500 on failure' do
        expect(subject.status).to eq 500
      end
    end
  end
end
