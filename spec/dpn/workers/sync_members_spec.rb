# -*- encoding: utf-8 -*-
require 'spec_helper'
require 'shared_examples/sync_registry_object'

describe DPN::Workers::SyncMembers, :vcr do
  let(:subject) { described_class.new local_node, remote_node }
  it_behaves_like 'sync_registry_object'

  ##
  # PRIVATE

  # Specs for SyncMembers that are not covered by sync_registry_object
  describe '#sync_members' do
    it 'logs errors from requests to remote_client.members' do
      response = double('response')
      allow(response).to receive(:success?).and_return(false)
      allow(response).to receive(:body).and_return('error message')
      allow(subject.remote_client).to receive(:members).and_yield(response)
      logger = subject.send(:logger)
      expect(logger).to receive(:error).at_least(:once).and_call_original
      expect(subject.sync).to be false
    end
  end
end
