# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GetaroundUtils::Utils::ConfigUrl do
  # rubocop:disable RSpec/NestedGroups
  describe '.from_env' do
    subject { described_class.from_env(config_name) }

    let(:config_name) { 'TEST_CONFIG' }

    let(:url_key) { "#{config_name}_URL" }
    let(:usr_key) { "#{config_name}_USERNAME" }
    let(:pwd_key) { "#{config_name}_PASSWORD" }

    let(:mocked_env) do
      {}
    end

    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with(url_key, any_args).and_wrap_original do |_, *args, &blk|
        mocked_env.fetch(*args, &blk)
      end
      allow(ENV).to receive(:fetch).with(usr_key, any_args).and_wrap_original do |_, *args, &blk|
        mocked_env.fetch(*args, &blk)
      end
      allow(ENV).to receive(:fetch).with(pwd_key, any_args).and_wrap_original do |_, *args, &blk|
        mocked_env.fetch(*args, &blk)
      end
    end

    context 'with empty userinfo in base url' do
      let(:mocked_env) do
        {
          url_key => 'mysql://@localhost:666/test',
        }
      end

      it 'cleanup the base url' do
        expect(subject).to be_a ::URI::Generic
        expect(subject.to_s).to eq 'mysql://localhost:666/test'
      end

      context 'with usr variable matching' do
        let(:mocked_env) do
          super().merge(usr_key => 'user42')
        end

        it 'computes it without adding pwd' do
          expect(subject).to be_a ::URI::Generic
          expect(subject.to_s).to eq 'mysql://user42@localhost:666/test'
        end
      end

      context 'with pwd variable matching' do
        let(:mocked_env) do
          super().merge(pwd_key => 'my-pwd')
        end

        it 'computes it correctly' do
          expect(subject).to be_a ::URI::Generic
          expect(subject.to_s).to eq 'mysql://:my-pwd@localhost:666/test'
        end
      end

      context 'with usr + pwd variables matching' do
        let(:mocked_env) do
          super().merge(usr_key => 'user42', pwd_key => 'my-pwd')
        end

        it 'computes it' do
          expect(subject).to be_a ::URI::Generic
          expect(subject.to_s).to eq 'mysql://user42:my-pwd@localhost:666/test'
        end
      end
    end

    context 'with blank credentials in base url' do
      let(:mocked_env) do
        {
          url_key => 'mysql://:@localhost:666/test',
        }
      end

      it 'keeps them blank' do
        expect(subject).to be_a ::URI::Generic
        expect(subject.to_s).to eq 'mysql://:@localhost:666/test'
      end

      context 'with usr variable matching' do
        let(:mocked_env) do
          super().merge(usr_key => 'user42')
        end

        it 'computes it keeping blank pwd' do
          expect(subject).to be_a ::URI::Generic
          expect(subject.to_s).to eq 'mysql://user42:@localhost:666/test'
        end
      end

      context 'with pwd variable matching' do
        let(:mocked_env) do
          super().merge(pwd_key => 'my-pwd')
        end

        it 'computes it correctly' do
          expect(subject).to be_a ::URI::Generic
          expect(subject.to_s).to eq 'mysql://:my-pwd@localhost:666/test'
        end
      end

      context 'with usr + pwd variables matching' do
        let(:mocked_env) do
          super().merge(usr_key => 'user42', pwd_key => 'my-pwd')
        end

        it 'computes it' do
          expect(subject).to be_a ::URI::Generic
          expect(subject.to_s).to eq 'mysql://user42:my-pwd@localhost:666/test'
        end
      end
    end

    context 'with a usr variable and no usr in base url' do
      let(:mocked_env) do
        {
          url_key => 'mysql://localhost:666/test',
          usr_key => 'user42',
        }
      end

      it 'computes the usr in the base url' do
        expect(subject).to be_a ::URI::Generic
        expect(subject.to_s).to eq 'mysql://user42@localhost:666/test'
      end
    end

    context 'with a usr variable matching and pwd already present in base url' do
      let(:mocked_env) do
        {
          url_key => 'mysql://:my-pwd@localhost:666/test',
          usr_key => 'user42',
        }
      end

      it 'computes the usr in the base url' do
        expect(subject).to be_a ::URI::Generic
        expect(subject.to_s).to eq 'mysql://user42:my-pwd@localhost:666/test'
      end
    end

    context 'with a usr variable matching and usr + pwd already present in base url' do
      let(:mocked_env) do
        {
          url_key => 'mysql://usr666:my-pwd@localhost:666/test',
          usr_key => 'user42',
        }
      end

      it 'overrides the usr in the base url' do
        expect(subject).to be_a ::URI::Generic
        expect(subject.to_s).to eq 'mysql://user42:my-pwd@localhost:666/test'
      end
    end

    context 'with a usr + pwd variable matching and usr + pwd already present in base url' do
      let(:mocked_env) do
        {
          url_key => 'mysql://usr666:my-pwd@localhost:666/test',
          usr_key => 'user42',
          pwd_key => 'new-pwd',
        }
      end

      it 'overrides the usr in the base url' do
        expect(subject).to be_a ::URI::Generic
        expect(subject.to_s).to eq 'mysql://user42:new-pwd@localhost:666/test'
      end
    end

    context 'with pwd variable but no username in base url' do
      let(:mocked_env) do
        {
          url_key => 'mysql://localhost:666/test',
          pwd_key => 'used-pwd',
        }
      end

      it 'computes the pwd in the base url' do
        expect(subject).to be_a ::URI::Generic
        expect(subject.to_s).to eq 'mysql://:used-pwd@localhost:666/test'
      end
    end

    context 'when credentials are already present in base url' do
      let(:mocked_env) do
        {
          url_key => 'mysql://user1:my-pwd@localhost:666/test',
        }
      end

      context 'with pwd variable matching' do
        let(:mocked_env) do
          super().merge(pwd_key => 'override-url-pwd')
        end

        it 'overrides the url password' do
          expect(subject).to be_a ::URI::Generic
          expect(subject.to_s).to eq 'mysql://user1:override-url-pwd@localhost:666/test'
        end
      end

      context 'with usr variable matching' do
        let(:mocked_env) do
          super().merge(usr_key => 'user42')
        end

        it 'overrides the url username' do
          expect(subject).to be_a ::URI::Generic
          expect(subject.to_s).to eq 'mysql://user42:my-pwd@localhost:666/test'
        end
      end
    end

    context 'when pwd is blank in base url' do
      let(:mocked_env) do
        {
          url_key => 'mysql://user2:@localhost:666/test',
          pwd_key => 'override-blank-pwd',
        }
      end

      it 'overrides the blank password' do
        expect(subject).to be_a ::URI::Generic
        expect(subject.to_s).to eq 'mysql://user2:override-blank-pwd@localhost:666/test'
      end
    end

    context 'with no pwd in base url and pwd variable' do
      let(:mocked_env) do
        {
          url_key => 'mysql://user3@localhost:666/test',
          pwd_key => 'must-be-used',
        }
      end

      it 'computes the pwd in the base url' do
        expect(subject).to be_a ::URI::Generic
        expect(subject.to_s).to eq 'mysql://user3:must-be-used@localhost:666/test'
      end
    end

    context 'with no pwd variable' do
      let(:mocked_env) do
        {
          url_key => 'mysql://user4@localhost:666/test',
        }
      end

      it 'returns the config url' do
        expect(subject).to be_a ::URI::Generic
        expect(subject.to_s).to eq 'mysql://user4@localhost:666/test'
      end
    end

    context 'with no pwd variable and no credentials in base url' do
      let(:mocked_env) do
        {
          url_key => 'mysql://localhost:666/test',
        }
      end

      it 'returns the config url' do
        expect(subject).to be_a ::URI::Generic
        expect(subject.to_s).to eq 'mysql://localhost:666/test'
      end
    end

    context 'with no host and no user and no pwd variable' do
      let(:mocked_env) do
        {
          url_key => 'sqlite:///db/test.db',
        }
      end

      it 'returns the config url' do
        expect(subject).to be_a ::URI::Generic
        expect(subject.to_s).to eq 'sqlite:///db/test.db'
      end
    end

    context 'with username in base url and pwd variable but no host' do
      let(:mocked_env) do
        {
          url_key => 'sqlite://user5@/db/test.db',
          pwd_key => 'pwd',
        }
      end

      it 'computes the pwd in the base url' do
        expect(subject).to be_a ::URI::Generic
        expect(subject.to_s).to eq 'sqlite://user5:pwd@/db/test.db'
      end
    end

    context 'with an unknown config name' do
      let(:config_name) { 'UNKNOWN_CONFIG' }

      let(:mocked_env) do
        {}
      end

      # rubocop:disable RSpec/MultipleMemoizedHelpers
      shared_examples 'with a fallback value' do
        let(:fallback_value) { 'postgresql://fallback@localhost:666/foo' }

        shared_examples 'with nil fallback' do
          let(:fallback_value) { nil }

          it { is_expected.to be_nil }
        end

        it 'returns the fallback value' do
          expect(subject).to be_a ::URI::Generic
          expect(subject.to_s).to eq 'postgresql://fallback@localhost:666/foo'
        end

        it_behaves_like 'with nil fallback'

        context 'with a usr variable matching' do
          let(:mocked_env) do
            super().merge(usr_key => 'user42')
          end

          it 'overrides the usr in the fallback value' do
            expect(subject).to be_a ::URI::Generic
            expect(subject.to_s).to eq 'postgresql://user42@localhost:666/foo'
          end

          it_behaves_like 'with nil fallback'

          context 'with blank pwd in the fallback value' do
            let(:fallback_value) { 'postgresql://fallback:@localhost:666/foo' }

            it 'overrides the usr in the fallback value keeping blank pwd' do
              expect(subject).to be_a ::URI::Generic
              expect(subject.to_s).to eq 'postgresql://user42:@localhost:666/foo'
            end

            it_behaves_like 'with nil fallback'
          end
        end

        context 'with a pwd variable matching' do
          let(:mocked_env) do
            super().merge(pwd_key => 'mocked-pwd')
          end

          it 'computes the pwd in the fallback value' do
            expect(subject).to be_a ::URI::Generic
            expect(subject.to_s).to eq 'postgresql://fallback:mocked-pwd@localhost:666/foo'
          end

          it_behaves_like 'with nil fallback'

          context 'with no username in fallback value' do
            let(:fallback_value) { 'postgresql://localhost:666/foo' }

            it 'computes the pwd in the base url' do
              expect(subject).to be_a ::URI::Generic
              expect(subject.to_s).to eq 'postgresql://:mocked-pwd@localhost:666/foo'
            end

            it_behaves_like 'with nil fallback'
          end
        end
      end
      # rubocop:enable RSpec/MultipleMemoizedHelpers

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
  end
  # rubocop:enable RSpec/NestedGroups
end
