# -*- encoding: utf-8 -*-
require 'spec_helper'
require 'shared_examples/sync_content'

describe DPN::Workers::SyncContent, :vcr do
  let(:content) { { id: 'content' } }
  let(:local_client) { local_node.client }
  let(:logger) { Logger.new(File::NULL) }
  subject { described_class.new content, local_client, logger }
  before do
    allow(subject).to receive(:content_id).and_return('content_id')
  end
  it_behaves_like 'sync_content'
end
