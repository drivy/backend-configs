require 'spec_helper'

describe GetaroundUtils::Mixins::Loggable do
  context 'when included in a class' do
    let(:dummy_logger) { double }
    let(:base_class) { stub_const('BaseClass', Class.new { include GetaroundUtils::Mixins::Loggable }) }
    let(:subject) { base_class.new }

    before { allow(subject).to receive(:base_loggable_logger).and_return(dummy_logger) }

    context 'with no inheritence' do
      it 'inject the class name' do
        expect(dummy_logger).to receive(:info)
          .with('key="value" origin="BaseClass"')
        subject.loggable(:info, key: :value)
      end

      it 'inject the appended info' do
        base_class.class_eval do
          def append_infos_to_loggable(payload)
            payload[:extra] = 'dummy'
          end
        end

        expect(dummy_logger).to receive(:info)
          .with('key="value" origin="BaseClass" extra="dummy"')
        subject.loggable(:info, key: :value)
      end
    end

    context 'with inheritence' do
      let(:child_class) { stub_const('ChildClass', Class.new(base_class)) }
      let(:subject) { child_class.new }

      it 'inject the class name' do
        expect(dummy_logger).to receive(:info)
          .with('key="value" origin="ChildClass"')
        subject.loggable(:info, key: :value)
      end

      it 'inherits the parent appended infos' do
        base_class.class_eval do
          def append_infos_to_loggable(payload)
            payload[:parent] = 'dummy'
          end
        end

        expect(dummy_logger).to receive(:info)
          .with('key="value" origin="ChildClass" parent="dummy"')
        subject.loggable(:info, key: :value)
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
          .with('key="value" origin="ChildClass" parent="dummy" child="dummy"')
        subject.loggable(:info, key: :value)
      end
    end
  end
end
