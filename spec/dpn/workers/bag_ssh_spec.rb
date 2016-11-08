# -*- encoding: utf-8 -*-
require 'spec_helper'

describe DPN::Workers::BagSSH do
  let(:settings) { SyncSettings.ssh }
  let(:subject) { described_class.new }

  it 'works' do
    expect(subject).to be_an described_class
    expect(subject).to respond_to(:identity_file)
    expect(subject).to respond_to(:user)
  end

  context 'user' do
    it 'is nil' do
      expect(settings).to receive(:user).and_return(nil)
      expect { subject }.not_to raise_error
      expect(subject.user).to be_nil
    end
    it 'is empty' do
      expect(settings).to receive(:user).and_return('')
      expect { subject }.not_to raise_error
      expect(subject.user).to be_empty
    end
    it 'returns SyncSettings.ssh.user' do
      ssh_user = 'ssh_user'
      expect(settings).to receive(:user).and_return(ssh_user)
      expect(subject.user).to eq ssh_user
    end
  end

  context 'identity_file' do
    it 'is nil' do
      expect(settings).to receive(:identity_file).and_return(nil)
      expect { subject }.not_to raise_error
      expect(subject.identity_file).to be_nil
    end
    it 'is empty' do
      expect(settings).to receive(:identity_file).and_return('')
      expect { subject }.not_to raise_error
      expect(subject.identity_file).to be_empty
    end
    it 'returns SyncSettings.ssh.identity_file' do
      ssh_file = 'ssh_identity_file'
      expect(settings).to receive(:identity_file).and_return(ssh_file)
      expect(subject.identity_file).to eq ssh_file
    end
  end

  describe "#retrieve_command" do
    let(:ssh_cmd) { subject.retrieve_command }
    let(:ssh_file) { 'ssh_identity_file' }
    let(:ssh_user) { 'ssh_user' }

    it 'works' do
      expect(ssh_cmd).not_to be_nil
    end

    it 'returns a String' do
      expect(ssh_cmd).to be_an String
    end

    context 'there is an ssh user and identity_file' do
      before do
        allow(subject).to receive(:identity_file).and_return(ssh_file)
        allow(subject).to receive(:user).and_return(ssh_user)
      end
      it 'starts with "ssh"' do
        expect(ssh_cmd).to start_with 'ssh'
      end
      it 'contains an option to disable PasswordAuthentication' do
        expect(ssh_cmd).to include '-o PasswordAuthentication=no'
      end
      it 'contains an option to disable UserKnownHostsFile' do
        expect(ssh_cmd).to include '-o UserKnownHostsFile=/dev/null'
      end
      it 'contains an option to disable StrictHostKeyChecking' do
        expect(ssh_cmd).to include '-o StrictHostKeyChecking=no'
      end
      it 'contains an option to specify the ssh user' do
        expect(ssh_cmd).to include "-l #{ssh_user}"
      end
      it 'contains an option to specify the ssh identity_file' do
        expect(ssh_cmd).to include "-i #{ssh_file}"
      end
    end

    context 'there is no ssh user' do
      before do
        allow(subject).to receive(:user).and_return('')
      end
      it 'returns a String' do
        expect(ssh_cmd).to be_an String
      end
      it 'returns an empty String' do
        expect(ssh_cmd).to be_empty
      end
    end

    context 'there is an ssh user, but no ssh identity_file' do
      before do
        allow(subject).to receive(:user).and_return('ssh_user')
        allow(subject).to receive(:identity_file).and_return('')
      end
      it 'returns a String' do
        expect(ssh_cmd).to be_an String
      end
      it 'returns an empty String' do
        expect(ssh_cmd).to be_empty
      end
    end
  end
end
