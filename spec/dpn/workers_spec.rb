# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers do
  describe '.nodes' do
    let(:subject) { described_class.nodes }
    it 'works' do
      expect(subject).to be_an DPN::Workers::Nodes
    end
    it 'uses Settings.nodes' do
      expect(Settings).to receive(:nodes).and_call_original
      subject
    end
    it 'uses Settings.local_namespace' do
      expect(Settings).to receive(:local_namespace).and_call_original
      subject
    end
  end

  describe '.create_logger' do
    let(:subject) { described_class.create_logger('name') }
    it 'works' do
      expect(subject).to be_an Logger
    end
    it 'uses Settings.log_level' do
      expect(Settings).to receive(:log_level).and_call_original
      subject
    end
    it 'defaults to Logger::INFO' do
      expect(Settings).to receive(:log_level).and_return('WHAT')
      expect(subject.level).to eq Logger::INFO
    end
  end
end
