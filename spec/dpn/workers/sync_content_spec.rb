# -*- encoding: utf-8 -*-
require 'spec_helper'
require 'shared_examples/sync_content'

describe DPN::Workers::SyncContent, :vcr do
  let(:content) { { id: 'content' } }
  let(:local_client) { local_node.client }
  let(:subject) { described_class.new content, local_client, null_logger }

  context 'with content_id' do
    before do
      allow(subject).to receive(:content_id).and_return('content_id')
    end
    it_behaves_like 'sync_content'
  end

  ##
  # PRIVATE

  describe '#content_id' do
    it 'raises NotImplementedError' do
      expect { subject.send(:content_id) }.to raise_error(NotImplementedError)
    end
  end

  describe '#create' do
    it 'raises NotImplementedError' do
      expect { subject.send(:create) }.to raise_error(NotImplementedError)
    end
  end

  describe '#update' do
    it 'raises NotImplementedError' do
      expect { subject.send(:update) }.to raise_error(NotImplementedError)
    end
  end
end
