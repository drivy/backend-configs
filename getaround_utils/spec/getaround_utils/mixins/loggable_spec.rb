# frozen_string_literal: true

require 'spec_helper'

describe GetaroundUtils::Mixins::Loggable do
  let(:dummy_logger) { double }

  describe '#loggable_logger' do
    it 'uses the class logger when available' do
      stub_const('BaseClass', Class.new{
        include GetaroundUtils::Mixins::Loggable
        def use_loggable(*args)
          loggable_log(*args)
        end
      })
      subject = BaseClass.new
      allow(subject).to receive(:logger)
        .and_return(dummy_logger)
      expect(subject.loggable_logger)
        .to eq(dummy_logger)
    end

    it 'uses the Rails logger when available' do
      stub_const('BaseClass', Class.new{
        include GetaroundUtils::Mixins::Loggable
        def use_loggable(*args)
          loggable_log(*args)
        end
      })
      stub_const('Rails', {})
      subject = BaseClass.new
      allow(Rails).to receive(:logger)
        .and_return(dummy_logger)
      expect(subject.loggable_logger)
        .to eq(dummy_logger)
    end

    it 'uses a safe fallback' do
      stub_const('BaseClass', Class.new{
        include GetaroundUtils::Mixins::Loggable
        def use_loggable(*args)
          loggable_log(*args)
        end
      })
      allow(Rails).to receive(:logger)
        .and_return(nil)
      subject = BaseClass.new
      allow(subject).to receive(:loggable_logger_fallback)
        .and_return(dummy_logger)
      expect(subject.loggable_logger)
        .to eq(dummy_logger)
    end
  end

  context 'when included in a static class' do
    before do
      allow(base_class).to receive(:loggable_logger)
        .and_return(dummy_logger)
    end

    let(:base_class) do
      stub_const('BaseClass', Class.new{
        class << self
          include GetaroundUtils::Mixins::Loggable

          def use_loggable(*args)
            loggable_log(*args)
          end
        end
      })
    end

    it 'injects the class name' do
      expect(dummy_logger).to receive(:error)
        .with(msg: 'test', origin: 'BaseClass')
      base_class.use_loggable(:error, 'test')
    end

    it 'inject the appended info' do
      base_class.class_eval do
        def self.append_infos_to_loggable(payload)
          payload[:extra] = 'dummy'
        end
      end

      expect(dummy_logger).to receive(:info)
        .with(msg: 'dummy', key: :value, origin: 'BaseClass', extra: 'dummy')
      base_class.use_loggable(:info, 'dummy', key: :value)
    end
  end

  context 'when included in a class' do
    let(:base_class) do
      stub_const('BaseClass', Class.new{
        include GetaroundUtils::Mixins::Loggable

        def use_loggable(*args)
          loggable_log(*args)
        end

        def loggable_logger
          @loggable_logger ||= Logger.new(nil)
        end
      })
    end

    let(:subject) { base_class.new }

    context 'with no inheritence' do
      it 'inject the class name' do
        expect(subject.loggable_logger).to receive(:info)
          .with(msg: 'dummy', key: :value, origin: 'BaseClass')
        subject.use_loggable(:info, 'dummy', key: :value)
      end

      it 'inject the appended info' do
        base_class.class_eval do
          def append_infos_to_loggable(payload)
            payload[:extra] = 'dummy'
          end
        end

        expect(subject.loggable_logger).to receive(:info)
          .with(msg: 'dummy', key: :value, origin: 'BaseClass', extra: 'dummy')
        subject.use_loggable(:info, 'dummy', key: :value)
      end
    end

    context 'with inheritence' do
      let(:child_class) { stub_const('ChildClass', Class.new(base_class)) }
      let(:subject) { child_class.new }

      it 'inject the class name' do
        expect(subject.loggable_logger).to receive(:info)
          .with(msg: 'dummy', key: :value, origin: 'ChildClass')
        subject.use_loggable(:info, 'dummy', key: :value)
      end

      it 'inherits the parent appended infos' do
        base_class.class_eval do
          def append_infos_to_loggable(payload)
            payload[:parent] = 'dummy'
          end
        end

        expect(subject.loggable_logger).to receive(:info)
          .with(msg: 'dummy', key: :value, origin: 'ChildClass', parent: 'dummy')
        subject.use_loggable(:info, 'dummy', key: :value)
      end

      it 'merges the parent the appended info' do
        base_class.class_eval do
          def append_infos_to_loggable(payload)
            payload[:parent] = 'dummy'
          end
        end
        child_class.class_eval do
          def append_infos_to_loggable(payload)
            super
            payload[:child] = 'dummy'
          end
        end

        expect(subject.loggable_logger).to receive(:info)
          .with(msg: 'dummy', key: :value, origin: 'ChildClass', parent: 'dummy', child: 'dummy')
        subject.use_loggable(:info, 'dummy', key: :value)
      end
    end
  end

  describe '#monitorable_log' do
    subject { base_class.new }

    before do
      allow(base_class).to receive(:loggable_logger)
        .and_return(dummy_logger)
      allow(Rails.application.config.monitorable_log_thresholds)
        .to receive(:dig)
        .with(event_name.to_sym)
        .and_return(10)
    end

    let(:base_class) do
      stub_const('BaseClass', Class.new{
        include GetaroundUtils::Mixins::Loggable

        def use_monitorable(*args, **kwargs)
          monitorable_log(*args, **kwargs)
        end
      })
    end
    let(:event_name) { 'dummy' }

    it 'logs message' do
      expect(subject.loggable_logger).to receive(:info).with(
        msg: "monitorable_log__#{event_name}",
        alert_threshold: 10,
        origin: "BaseClass"
      )
      subject.use_monitorable(event_name)
    end

    context 'with a threshold configured in environment' do
      before do
        allow(ENV).to receive(:[]).with('MONITORABLE_LOG__DUMMY_THRESHOLD').and_return('20')
      end

      it 'logs message with environment threshold' do
        expect(subject.loggable_logger).to receive(:info).with(
          msg: "monitorable_log__#{event_name}",
          alert_threshold: 20,
          origin: "BaseClass"
        )
        subject.use_monitorable(event_name)
      end
    end

    context 'with extra arguments' do
      it 'logs message with environment threshold' do
        expect(subject.loggable_logger).to receive(:info).with(
          msg: "monitorable_log__#{event_name}",
          alert_threshold: 10,
          origin: "BaseClass",
          extra: "argument"
        )
        subject.use_monitorable(event_name, extra: "argument")
      end
    end

    context 'with no thresholds configured' do
      before do
        allow(base_class).to receive(:loggable_logger)
          .and_return(dummy_logger)
        allow(Rails.application.config.monitorable_log_thresholds)
          .to receive(:dig)
          .with(event_name.to_sym)
          .and_return(nil)
      end

      it 'does not log anything' do
        expect(subject.loggable_logger).not_to receive(:info)
        subject.use_monitorable(event_name)
      end
    end
  end
end
