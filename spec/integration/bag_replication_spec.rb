# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::BagReplication, :vcr do
  let(:admin_node) { nodes.node('hathi') }

  # let(:settings) { SyncSettings.replication }

  def replication_transfer
    admin_node.client.replications do |response|
      rep = response.body
      return rep if rep[:to_node] == local_node.namespace
    end
  end

  it 'works' do
    # Get a replication from an admin node for this local node.
    repl = replication_transfer
    subject = described_class.new repl
    expect(subject.replicate).to be true
    bagit = subject.send(:bagit)
    expect(File.exist?(bagit.location)).to be true
  end
end
