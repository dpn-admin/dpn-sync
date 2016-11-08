# -*- encoding: utf-8 -*-

RSpec.shared_examples 'sync_registry_object_success' do
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
  end
end
