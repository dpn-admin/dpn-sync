# -*- encoding: utf-8 -*-
require 'spec_helper'
require 'shared_examples/sync_registry_object_success'

describe DPN::Workers::SyncReplications, :vcr do
  before do
    # Ensure there are some bags from the remote node available
    sync_bags = DPN::Workers::SyncBags.new(local_node, remote_node)
    sync_bags.sync
  end

  let(:subject) { described_class.new local_node, remote_node }
  it_behaves_like 'sync_registry_object_success'
  # it DOES NOT behave like 'sync_registry_object_failure'

  context 'failure' do
    let(:failure_nodes) { described_class.new local_node, example_node }
    it 'returns false when it is not configured to replicate from node' do
      expect(failure_nodes).not_to receive(:sync_replications)
      expect(failure_nodes.sync).to be false
    end
  end

  ##
  # PRIVATE

  # Specs for SyncMembers that are not covered by sync_registry_object
  describe '#sync_replications' do
    it 'logs errors from requests to remote_client.replications' do
      response = double('response')
      allow(response).to receive(:success?).and_return(false)
      allow(response).to receive(:body).and_return('error message')
      allow(subject.remote_client).to receive(:replications).and_yield(response)
      logger = subject.send(:logger)
      expect(logger).to receive(:error).at_least(:once).and_call_original
      expect(subject.sync).to be false
    end
  end
end
