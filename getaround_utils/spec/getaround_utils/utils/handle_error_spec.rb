# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GetaroundUtils::Utils::HandleError do
  describe '.notify_of' do
    let(:error) { RuntimeError.new('woopsie') }

    before do
      allow(described_class).to receive(:loggable_log)
    end

    shared_context 'with Bugsnag defined' do
      let(:bugsnag) { double }
      let(:event)   { double }

      before do
        allow(event).to receive(:add_metadata)
        allow(bugsnag).to receive(:notify).and_yield(event)
        stub_const('Bugsnag', bugsnag)
      end
    end

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

    context 'when Bugsnag is defined' do
      include_context 'with Bugsnag defined'

      it 'yields bugsnag event and notifies', :aggregate_failures do
        expect { |b| described_class.notify_of(error, &b) }.to yield_with_args(event)
        expect(bugsnag).to have_received(:notify).with(error)
        expect(event).not_to have_received(:add_metadata)
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

      # rubocop:disable RSpec/NestedGroups
      context 'when Bugsnag is defined' do
        include_context 'with Bugsnag defined'

        it 'adds metadata to bugsnag event then yields it and notifies', :aggregate_failures do
          expect { |b| described_class.notify_of(error, **metadata, &b) }.to yield_with_args(event)
          expect(bugsnag).to have_received(:notify).with(error)
          expect(event).to have_received(:add_metadata).with('custom', :foo, 'bar')
          expect(event).to have_received(:add_metadata).with(:baz, { hello: 'world' })
        end
      end
      # rubocop:enable RSpec/NestedGroups
    end
  end
end
