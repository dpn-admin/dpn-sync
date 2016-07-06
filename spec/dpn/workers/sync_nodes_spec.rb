# -*- encoding: utf-8 -*-
require 'spec_helper'
require 'shared_examples/sync_registry_object'

describe DPN::Workers::SyncNodes, :vcr do
  subject { described_class.new local_node, remote_node }
  it_behaves_like 'sync_registry_object'
end
