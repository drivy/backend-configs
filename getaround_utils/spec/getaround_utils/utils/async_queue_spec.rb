require "spec_helper"

describe GetaroundUtils::Utils::AsyncQueue do
  describe 'functionnal test' do
    let(:subject) { described_class.new }

    after do
      subject.terminate
    end

    it 'performs the queued tasks in another thread' do
      main_thread_id = Thread.current.object_id
      allow(subject).to receive(:perform) do
        expect(Thread.current.object_id).not_to eq(main_thread_id)
      end

      subject.push(1)
      subject.terminate

      expect(subject).to have_received(:perform)
    end

    it 'does not block the main thread flow' do
      allow(subject).to receive(:perform) { sleep(0.3) }

      ts_started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      subject.push(1)
      main_duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - ts_started

      subject.terminate
      task_duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - ts_started

      expect(main_duration).to be_within(0.1).of(0)
      expect(task_duration).to be_within(0.1).of(1.3)
    end

    it 'performs all the queued items' do
      collected_items = []
      allow(subject).to receive(:perform) { |items| collected_items.push(*items) }

      256.times { subject.push(1) }
      subject.terminate

      expect(collected_items.size).to equal(256)
      expect(subject).to have_received(:perform)
        .at_most(256).times
    end

    it 'logs dropped tasks when the queue overflows' do
      allow(subject).to receive(:loggable_log)
      allow(subject).to receive(:perform) { sleep(0.005) }

      2000.times { subject.push(1) }
      subject.terminate

      expect(subject).to have_received(:perform)
        .at_most((2000 / 50) - 1).times
      expect(subject).to have_received(:loggable_log)
        .with(:error, 'queue overflow')
        .at_least(1).times
    end

    it 'rescue and logs errors that are not handled in #perform and keeps unqueuing' do
      count = 0
      allow(subject).to receive(:loggable_log)
      allow(subject).to receive(:perform) do
        raise StandardError, 'Test error' if (count += 1) == 1
      end

      200.times { subject.push(1) }
      subject.terminate

      expect(subject).to have_received(:perform)
        .at_least(200 / 50).times
      expect(subject).to have_received(:loggable_log)
        .with(:error, 'Test error', hash_including(class: 'StandardError')).once
    end
  end

  describe 'concurency' do
    let(:subject1) { described_class.new }
    let(:subject2) { described_class.new }

    after do
      subject1.terminate
      subject2.terminate
    end

    it 'two queues do not block each other' do
      allow(subject1).to receive(:perform) { puts("1a"); sleep(0.3); puts("1b"); }
      allow(subject2).to receive(:perform) { puts("2a"); sleep(0.7); puts("2b"); }

      ts_started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      subject1.push(1)
      subject2.push(1)
      push_duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - ts_started

      subject1.terminate
      task_1_duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - ts_started
      subject2.terminate
      task_2_duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - ts_started

      expect(push_duration).to be_within(0.01).of(0)
      expect(task_1_duration).to be_within(0.1).of(1.3)
      expect(task_2_duration).to be_within(0.1).of(1.7)
    end
  end
end
