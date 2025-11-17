# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GetaroundUtils::Utils::ConfigUrl do
  describe '.from_env' do
    subject { described_class.from_env(config_name) }

    let(:mocked_env) do
      {
        'TEST_URL_PWD_URL' => "mysql://user1:my-pwd@localhost:666/test",
        'TEST_URL_PWD_PASSWORD' => "not-used-because-present-in-url",
        'TEST_BLANK_PWD_URL' => "mysql://user2:@localhost:666/test",
        'TEST_BLANK_PWD_PASSWORD' => "not-used-because-present-in-url-even-if-blank",
        'TEST_COMPUTE_URL' => "mysql://user3@localhost:666/test",
        'TEST_COMPUTE_PASSWORD' => "must-be-used",
        'TEST_NO_PWD_URL' => "mysql://user4@localhost:666/test",
        'TEST_NO_AUTH_URL' => "mysql://localhost:666/test",
        'TEST_NO_HOST_NO_AUTH_URL' => "sqlite:///db/test.db",
        'TEST_NO_HOST_URL' => "sqlite://user5@/db/test.db",
        'TEST_NO_HOST_PASSWORD' => "pwd",
        'TEST_NO_USERNAME_URL' => "mysql://localhost:666/test",
        'TEST_NO_USERNAME_PASSWORD' => "used-pwd",
      }
    end

    before do
      allow(ENV).to receive(:key?).and_call_original
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("#{config_name}_URL", any_args).and_wrap_original do |_, *args, &blk|
        mocked_env.fetch(*args, &blk)
      end
      allow(ENV).to receive(:fetch).with("#{config_name}_PASSWORD", any_args).and_wrap_original do |_, *args, &blk|
        mocked_env.fetch(*args, &blk)
      end
      allow(ENV).to receive(:key?).with("#{config_name}_PASSWORD").and_return(mocked_env.key?("#{config_name}_PASSWORD"))
    end

    context 'with pwd variable but no username in base url' do
      let(:config_name) { 'TEST_NO_USERNAME' }

      it { expect { subject }.to raise_error(URI::InvalidURIError, /password component depends user component/) }
    end

    context 'when pwd is already present in base url' do
      let(:config_name) { 'TEST_URL_PWD' }

      it 'does not replace the url password' do
        expect(subject).to be_a ::URI::Generic
        expect(subject.to_s).to eq "mysql://user1:my-pwd@localhost:666/test"
      end
    end

    context 'when pwd is blank in base url' do
      let(:config_name) { 'TEST_BLANK_PWD' }

      it 'does not replace the url password' do
        expect(subject).to be_a ::URI::Generic
        expect(subject.to_s).to eq "mysql://user2:@localhost:666/test"
      end
    end

    context 'with no pwd in base url and pwd variable' do
      let(:config_name) { 'TEST_COMPUTE' }

      it 'computes the pwd in the base url' do
        expect(subject).to be_a ::URI::Generic
        expect(subject.to_s).to eq "mysql://user3:must-be-used@localhost:666/test"
      end
    end

    context 'with no pwd variable' do
      let(:config_name) { 'TEST_NO_PWD' }

      it 'returns the config url' do
        expect(subject).to be_a ::URI::Generic
        expect(subject.to_s).to eq "mysql://user4@localhost:666/test"
      end
    end

    context 'with no pwd variable and no credentials in base url' do
      let(:config_name) { 'TEST_NO_AUTH' }

      it 'returns the config url' do
        expect(subject).to be_a ::URI::Generic
        expect(subject.to_s).to eq "mysql://localhost:666/test"
      end
    end

    context 'with no host and no user and no pwd variable' do
      let(:config_name) { 'TEST_NO_HOST_NO_AUTH' }

      it 'returns the config url' do
        expect(subject).to be_a ::URI::Generic
        expect(subject.to_s).to eq "sqlite:///db/test.db"
      end
    end

    context 'with username in base url and pwd variable but no host' do
      let(:config_name) { 'TEST_NO_HOST' }

      it 'computes the pwd in the base url' do
        expect(subject).to be_a ::URI::Generic
        expect(subject.to_s).to eq "sqlite://user5:pwd@/db/test.db"
      end
    end

    # rubocop:disable RSpec/NestedGroups
    context 'with an unknown config name' do
      let(:config_name) { 'UNKNOWN_CONFIG' }

      shared_examples 'with a fallback value' do
        let(:fallback_value) { 'postgresql://fallback@localhost:666/foo' }

        shared_examples 'with nil fallback' do
          let(:fallback_value) { nil }

          it { is_expected.to be_nil }
        end

        it 'returns the fallback value' do
          expect(subject).to be_a ::URI::Generic
          expect(subject.to_s).to eq "postgresql://fallback@localhost:666/foo"
        end

        it_behaves_like 'with nil fallback'

        context 'with a pwd variable matching' do
          before do
            allow(ENV).to receive(:key?).with('UNKNOWN_CONFIG_PASSWORD').and_return(true)
            allow(ENV).to receive(:fetch).with('UNKNOWN_CONFIG_PASSWORD').and_return('mocked-pwd')
          end

          it 'computes the pwd in the fallback value' do
            expect(subject).to be_a ::URI::Generic
            expect(subject.to_s).to eq "postgresql://fallback:mocked-pwd@localhost:666/foo"
          end

          it_behaves_like 'with nil fallback'

          context 'with no username in fallback value' do
            let(:fallback_value) { 'postgresql://localhost:666/foo' }

            it { expect { subject }.to raise_error(URI::InvalidURIError, /password component depends user component/) }

            it_behaves_like 'with nil fallback'
          end
        end
      end

      it { expect { subject }.to raise_error(KeyError, /UNKNOWN_CONFIG_URL/) }

      context 'with a fallback value arg' do
        subject do
          described_class.from_env(config_name, fallback_value)
        end

        it_behaves_like 'with a fallback value'
      end

      context 'with a fallback value block' do
        subject do
          described_class.from_env(config_name) { fallback_value }
        end

        it_behaves_like 'with a fallback value'
      end
    end
    # rubocop:enable RSpec/NestedGroups
  end
end
