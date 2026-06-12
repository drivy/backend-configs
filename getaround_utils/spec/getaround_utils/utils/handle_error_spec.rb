# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GetaroundUtils::Utils::HandleError do
  # rubocop:disable RSpec/NestedGroups
  describe '.notify_of' do
    let(:error) { RuntimeError.new('woopsie') }

    before do
      allow(described_class).to receive(:loggable_log)
    end

    shared_context 'with Bugsnag defined' do
      let(:api_key) { 'my-api-key' }
      let(:bugsnag) { double }
      let(:event)   { double }
      let(:config)  { double(api_key:) }

      before do
        allow(event).to receive(:add_metadata)
        allow(bugsnag).to receive(:notify).and_yield(event)
        allow(bugsnag).to receive(:configuration).and_return(config)
        stub_const('Bugsnag', bugsnag)
      end
    end

    shared_examples 'logs the handled error' do
      it 'logs the handled error', :aggregate_failures do
        expect { |b| described_class.notify_of(error, &b) }.not_to yield_control
        expect(described_class)
          .to have_received(:loggable_log)
          .with(
            :debug,
            'handled_error',
            error_class: 'RuntimeError',
            error_message: 'woopsie'
          )
      end
    end

    it_behaves_like 'logs the handled error'

    context 'when Bugsnag is defined' do
      include_context 'with Bugsnag defined'

      it 'yields bugsnag event and notifies', :aggregate_failures do
        expect { |b| described_class.notify_of(error, &b) }.to yield_with_args(event)
        expect(bugsnag).to have_received(:notify).with(error)
        expect(event).not_to have_received(:add_metadata)
      end

      context 'without configured api key' do
        let(:api_key) { nil }

        it_behaves_like 'logs the handled error'
      end
    end

    context 'when providing metadata' do
      let(:metadata) do
        {
          foo: 'bar',
          baz: {
            hello: 'world',
          },
        }
      end

      shared_examples 'logs the handled error with given metadata' do
        it 'logs the handled error with given metadata', :aggregate_failures do
          expect { |b| described_class.notify_of(error, **metadata, &b) }.not_to yield_control
          expect(described_class)
            .to have_received(:loggable_log)
            .with(
              :debug,
              'handled_error',
              error_class: 'RuntimeError',
              error_message: 'woopsie',
              **metadata
            )
        end
      end

      it_behaves_like 'logs the handled error with given metadata'

      context 'when Bugsnag is defined' do
        include_context 'with Bugsnag defined'

        it 'adds metadata to bugsnag event then yields it and notifies', :aggregate_failures do
          expect { |b| described_class.notify_of(error, **metadata, &b) }.to yield_with_args(event)
          expect(bugsnag).to have_received(:notify).with(error)
          expect(event).to have_received(:add_metadata).with('custom', :foo, 'bar')
          expect(event).to have_received(:add_metadata).with(:baz, { hello: 'world' })
        end

        context 'without configured api key' do
          let(:api_key) { nil }

          it_behaves_like 'logs the handled error with given metadata'
        end
      end
    end
  end
  # rubocop:enable RSpec/NestedGroups
end
