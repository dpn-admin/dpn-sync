# -*- encoding: utf-8 -*-
require 'spec_helper'
require 'shared_examples/sync_registry_object'

describe DPN::Workers::SyncBags, :vcr do
  subject { described_class.new local_node, remote_node }
  it_behaves_like 'sync_registry_object'

  describe '#bag_query' do
    it 'returns a Hash for a bag query' do
      bag_type = described_class::BAG_TYPES.first
      result = subject.bag_query(bag_type)
      expect(result).to be_an Hash
      expect(result).to include(:bag_type)
      expect(result).to include(:admin_node)
      expect(result).to include(:after)
    end
  end
end
