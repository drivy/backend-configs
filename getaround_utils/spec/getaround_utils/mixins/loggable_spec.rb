require 'spec_helper'

describe GetaroundUtils::Mixins::Loggable do
  let(:dummy_logger) { double }

  context 'when included in a static class' do
    before do
      allow(base_class).to receive(:base_loggable_logger)
        .and_return(dummy_logger)
    end

    let(:base_class) do
      stub_const('BaseClass', Class.new{
        class << self
          include GetaroundUtils::Mixins::Loggable

          def use_loggable(*args)
            loggable_log(*args)
          end

          def use_deprecated_loggable(*args)
            loggable(*args)
          end
        end
      })
    end

    it 'injects the class name' do
      expect(dummy_logger).to receive(:error)
        .with('message="test" origin="BaseClass"')
      base_class.use_loggable(:error, 'test')
    end

    it 'inject the appended info' do
      base_class.class_eval do
        def self.append_infos_to_loggable(payload)
          payload[:extra] = 'dummy'
        end
      end

      expect(dummy_logger).to receive(:info)
        .with('message="dummy" key="value" origin="BaseClass" extra="dummy"')
      base_class.use_loggable(:info, 'dummy', key: :value)
    end

    it 'log warning calling the deprecated function name' do
      expect(dummy_logger).to receive(:error)
        .with('message="test" origin="BaseClass"')
      expect(dummy_logger).to receive(:warn)
      base_class.use_deprecated_loggable(:error, 'test')
    end
  end

  context 'when included in a class' do
    let(:base_class) do
      stub_const('BaseClass', Class.new{
        include GetaroundUtils::Mixins::Loggable

        def use_loggable(*args)
          loggable_log(*args)
        end

        def use_deprecated_loggable(*args)
          loggable(*args)
        end
      })
    end

    let(:subject) { base_class.new }

    before do
      allow(subject).to receive(:base_loggable_logger)
        .and_return(dummy_logger)
    end

    context 'with no inheritence' do
      it 'inject the class name' do
        expect(dummy_logger).to receive(:info)
          .with('message="dummy" key="value" origin="BaseClass"')
        subject.use_loggable(:info, 'dummy', key: :value)
      end

      it 'inject the appended info' do
        base_class.class_eval do
          def append_infos_to_loggable(payload)
            payload[:extra] = 'dummy'
          end
        end

        expect(dummy_logger).to receive(:info)
          .with('message="dummy" key="value" origin="BaseClass" extra="dummy"')
        subject.use_loggable(:info, 'dummy', key: :value)
      end

      it 'log warning calling the deprecated function name' do
        expect(dummy_logger).to receive(:info)
          .with('message="dummy" key="value" origin="BaseClass"')
        expect(dummy_logger).to receive(:warn)
        subject.use_deprecated_loggable(:info, 'dummy', key: :value)
      end
    end

    context 'with inheritence' do
      let(:child_class) { stub_const('ChildClass', Class.new(base_class)) }
      let(:subject) { child_class.new }

      it 'inject the class name' do
        expect(dummy_logger).to receive(:info)
          .with('message="dummy" key="value" origin="ChildClass"')
        subject.use_loggable(:info, 'dummy', key: :value)
      end

      it 'inherits the parent appended infos' do
        base_class.class_eval do
          def append_infos_to_loggable(payload)
            payload[:parent] = 'dummy'
          end
        end

        expect(dummy_logger).to receive(:info)
          .with('message="dummy" key="value" origin="ChildClass" parent="dummy"')
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

        expect(dummy_logger).to receive(:info)
          .with('message="dummy" key="value" origin="ChildClass" parent="dummy" child="dummy"')
        subject.use_loggable(:info, 'dummy', key: :value)
      end
    end
  end
end
