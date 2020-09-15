# frozen_string_literal: true

require 'spec_helper'

describe GetaroundUtils::Ougai::JsonFormatter do
  subject { described_class.new }

  describe '#_call' do
    it 'correctly formats a string' do
      expect(subject._call('INFO', nil, nil, { msg: 'string' }))
        .to eq(%{{"severity":"INFO","msg":"string"}\n})
    end

    it 'correctly formats a payload' do
      expect(subject._call('INFO', nil, nil, { msg: 'string', key: :value }))
        .to eq(%{{"severity":"INFO","msg":"string","key":"value"}\n})
    end

    it 'ignore empty messages' do
      expect(subject._call('INFO', nil, nil, { msg: 'No message', key: :value }))
        .to eq(%{{"severity":"INFO","key":"value"}\n})
    end

    it 'include appname when provided' do
      expect(subject._call('INFO', nil, 'appname', { msg: 'string', key: :value }))
        .to eq(%{{"severity":"INFO","progname":"appname","msg":"string","key":"value"}\n})
    end
  end
end
