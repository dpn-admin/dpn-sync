# -*- encoding: utf-8 -*-

RSpec.shared_examples 'sync_registry_object_failure' do
  describe '#sync' do
    context 'failure' do
      let(:failure_nodes) { described_class.new local_node, example_node }
      it 'raises exception on failure to connect to node' do
        RSpec::Expectations.configuration.on_potential_false_positives = :nothing
        expect { failure_nodes.sync }.to raise_error
        RSpec::Expectations.configuration.on_potential_false_positives = :warn
      end
    end
  end
end
