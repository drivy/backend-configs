require "spec_helper"

describe GetaroundUtils::Utils::AsyncQueue do
  let(:dummy_class) do
    Class.new(described_class) do
      def self.perform(*_arg); end
    end
  end

  after do
    dummy_class.reset
  end

  describe '.perform_async' do
    it 'performs all the queued tasks' do
      allow(dummy_class).to receive(:perform)

      99.times { dummy_class.perform_async(1) }
      dummy_class.terminate

      expect(dummy_class).to have_received(:perform)
        .with(1).exactly(99).times
    end

    it 'performs the queued tasks in another thread' do
      main_thread_id = Thread.current.object_id
      allow(dummy_class).to receive(:perform) do
        expect(Thread.current.object_id).not_to eq(main_thread_id)
      end

      dummy_class.perform_async(1)
      dummy_class.terminate

      expect(dummy_class).to have_received(:perform)
    end

    it 'does not block the main thread flow' do
      allow(dummy_class).to receive(:perform) do
        sleep 0.5
      end

      ts_started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      dummy_class.perform_async(1)
      main_duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - ts_started

      dummy_class.terminate
      task_duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - ts_started

      expect(main_duration).to be_within(0.01).of(0)
      expect(task_duration).to be_within(0.01).of(0.5)
    end

    it 'logs dropped tasks when the queue overflows' do
      allow(dummy_class).to receive(:loggable)
      allow(dummy_class).to receive(:perform) do
        sleep 0.005
      end

      1000.times { dummy_class.perform_async(1) }
      dummy_class.terminate

      expect(dummy_class).to have_received(:perform)
        .at_most(200).times
      expect(dummy_class).to have_received(:loggable)
        .with('warn', 'Queue is overflowing')
        .at_least(800).times
    end

    it 'rescue and logs errors that are not handled in #perform' do
      allow(dummy_class).to receive(:loggable)
      allow(dummy_class).to receive(:perform)
        .and_raise(StandardError, 'Test error')

      dummy_class.perform_async(1)
      dummy_class.terminate

      expect(dummy_class).to have_received(:loggable)
        .with('error', 'Test error', hash_including(class: 'StandardError'))
    end
  end
end
