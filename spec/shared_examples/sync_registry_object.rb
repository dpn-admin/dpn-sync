# -*- encoding: utf-8 -*-

RSpec.shared_examples 'sync_registry_object' do
  describe '#sync' do
    context 'success' do
      it 'returns true' do
        expect(subject.sync).to be true
      end
      it 'logs success' do
        logger = subject.send(:logger)
        expect(logger).to receive(:info).at_least(:once).and_call_original
        expect(subject.sync).to be true
      end
      it 'records success timestamp' do
        expect(subject).to receive(:last_success_update).once.and_call_original
        expect(subject.sync).to be true
      end
    end

    context 'failure' do
      let(:failure_nodes) { described_class.new local_node, example_node }
      it 'returns false' do
        expect(failure_nodes.sync).to be false
      end
      it 'logs failure' do
        logger = failure_nodes.send(:logger)
        expect(logger).to receive(:error).at_least(:once).and_call_original
        expect(failure_nodes.sync).to be false
      end
    end
  end
end
