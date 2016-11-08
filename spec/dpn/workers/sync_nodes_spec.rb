# -*- encoding: utf-8 -*-
require 'spec_helper'
require 'shared_examples/sync_registry_object_success'
require 'shared_examples/sync_registry_object_failure'

describe DPN::Workers::SyncNodes, :vcr do
  let(:subject) { described_class.new local_node, remote_node }
  it_behaves_like 'sync_registry_object_success'
  it_behaves_like 'sync_registry_object_failure'
end
