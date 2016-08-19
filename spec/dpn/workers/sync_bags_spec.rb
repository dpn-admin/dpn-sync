# -*- encoding: utf-8 -*-
require 'spec_helper'
require 'shared_examples/sync_registry_object'

describe DPN::Workers::SyncBags, :vcr do
  let(:subject) { described_class.new local_node, remote_node }
  it_behaves_like 'sync_registry_object'

  ##
  # PRIVATE

  describe '#bag_query' do
    it 'returns a Hash for a bag query' do
      result = subject.send(:bag_query, 'bag_type')
      expect(result).to be_an Hash
      expect(result).to include(:bag_type)
      expect(result).to include(:admin_node)
      expect(result).to include(:after)
    end
  end

  # Specs for SyncBags that are not covered by sync_registry_object
  describe '#sync_bags' do
    it 'calls #sync_bag_type' do
      expect(subject).to receive(:sync_bags).and_call_original
      expect(subject).to receive(:sync_bag_type).with('D').and_return(true)
      expect(subject).to receive(:sync_bag_type).with('I').and_return(true)
      expect(subject).to receive(:sync_bag_type).with('R').and_return(true)
      expect(subject.sync).to be true
    end
    it 'logs errors from requests to remote_client.bags' do
      response = double('response')
      allow(response).to receive(:success?).and_return(false)
      allow(response).to receive(:body).and_return('error message')
      allow(subject.remote_client).to receive(:bags).and_yield(response)
      logger = subject.send(:logger)
      expect(logger).to receive(:error).at_least(:once).and_call_original
      expect(subject.sync).to be false
    end
  end
end
