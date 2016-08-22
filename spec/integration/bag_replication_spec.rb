# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::BagReplication, :vcr do
  let(:admin_node) { nodes.node('chron') }

  # let(:settings) { SyncSettings.replication }

  it 'works' do
    # Get a replication from an admin node for this local node
    replication = nil
    admin_node.client.replications do |response|
      repl = response.body
      replication = repl if repl[:to_node] == local_node.namespace
    end
    # Hack to ensure the replication is compatible with the api-v1 server assumptions
    replication.delete :fixity_accept
    replication.delete :bag_valid
    replication[:bag] = replication[:uuid]
    replication.delete :uuid
    subject = described_class.new replication
    subject.replicate
  end
end
