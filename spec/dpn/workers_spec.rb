# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers do
  let(:settings) { SyncSettings }
  describe '.nodes' do
    before do
      expect(DPN::Workers::Nodes).to receive(:new).and_call_original
    end
    it 'works' do
      expect(subject.nodes).to be_an DPN::Workers::Nodes
    end
    it 'uses SyncSettings.nodes' do
      expect(settings).to receive(:nodes).and_call_original
      subject.nodes
    end
    it 'uses SyncSettings.local_namespace' do
      expect(settings).to receive(:local_namespace).and_call_original
      subject.nodes
    end
  end

  describe '.create_logger' do
    let(:logger) { subject.create_logger('name') }
    it 'works' do
      expect(logger).to be_an Logger
    end
    it 'uses SyncSettings.log_level' do
      expect(settings).to receive(:log_level).and_call_original
      logger
    end
    it 'defaults to Logger::INFO' do
      expect(settings).to receive(:log_level).and_return('WHAT')
      expect(logger.level).to eq Logger::INFO
    end
  end
end
