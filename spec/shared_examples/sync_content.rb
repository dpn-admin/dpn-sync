# -*- encoding: utf-8 -*-
require 'spec_helper'

RSpec.shared_examples 'sync_content' do
  describe '#create_or_update' do
    it 'calls #create' do
      expect(subject).to receive(:create).and_return(true)
      expect(subject).not_to receive(:update)
      subject.create_or_update
    end
    it 'calls #update when #create fails' do
      expect(subject).to receive(:create).and_return(false)
      expect(subject).to receive(:update).and_return(true)
      subject.create_or_update
    end
    it 'logs exceptions' do
      error = RuntimeError.new 'create failure'
      expect(subject).to receive(:create).and_raise(error)
      expect(subject).not_to receive(:update)
      expect(logger).to receive(:error).with(/FAILED/)
      expect(logger).to receive(:error).with(/create failure/)
      subject.create_or_update
    end
  end
end
