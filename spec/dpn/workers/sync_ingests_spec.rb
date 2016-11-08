# -*- encoding: utf-8 -*-
require 'spec_helper'
require 'shared_examples/sync_registry_object_success'
require 'shared_examples/sync_registry_object_failure'

describe DPN::Workers::SyncIngests, :vcr do
  let(:subject) { described_class.new local_node, remote_node }
  it_behaves_like 'sync_registry_object_success'
  it_behaves_like 'sync_registry_object_failure'

  ##
  # PRIVATE

  # Specs for SyncIngests that are not covered by sync_registry_object
  describe '#sync_ingests' do
    it 'logs errors from requests to remote_client.ingests' do
      response = double('response')
      allow(response).to receive(:success?).and_return(false)
      allow(response).to receive(:body).and_return('error message')
      allow(subject.remote_client).to receive(:ingests).and_yield(response)
      logger = subject.send(:logger)
      expect(logger).to receive(:error).at_least(:once).and_call_original
      expect(subject.sync).to be false
    end
  end
end
