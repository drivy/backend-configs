require 'logger'
require "spec_helper"

describe GetaroundUtils::LogFormatters::DeepKeyValue do
  describe GetaroundUtils::LogFormatters::DeepKeyValue::Base do
    context 'when using via a Logger' do
      let(:output) { Tempfile.new }
      let(:logger) do
        logger = Logger.new(output)
        logger.formatter = subject
        logger
      end

      it 'works with raw Strings' do
        expect(output).to receive(:write)
          .with(%{severity="INFO" message="string"\n})
        logger.info('string')
      end

      it 'works with formatted Strings' do
        expect(output).to receive(:write)
          .with(%{severity="INFO" key=value\n})
        logger.info('key=value')
      end

      it 'works with extra long strings' do
        expect(output).to receive(:write)
          .with(%{severity="INFO" message="#{'x' * 512} ..."\n})
        logger.info('x' * 1000)
      end

      it 'works with progname' do
        expect(output).to receive(:write)
          .with(%{severity="INFO" appname="dummy" message="string"\n})
        logger.info('dummy') { 'string' }
      end

      it 'works with Hashes' do
        expect(output).to receive(:write)
          .with(%{severity="INFO" key="value"\n})
        logger.info(key: 'value')
      end
    end
  end

  describe 'legacy'  do
    describe '.new'  do
      it 'return a Base variant' do
        expect(described_class.new).to be_a(GetaroundUtils::LogFormatters::DeepKeyValue::Base)
      end
    end

    describe '.for_lograge' do
      it 'return a Lograge variant' do
        expect(described_class.for_lograge).to be_a(GetaroundUtils::LogFormatters::DeepKeyValue::Lograge)
      end
    end

    describe '.for_sidekiq' do
      it 'return a Sidekiq variant' do
        expect(described_class.for_sidekiq).to be_a(GetaroundUtils::LogFormatters::DeepKeyValue::Sidekiq)
      end
    end
  end

  describe GetaroundUtils::LogFormatters::DeepKeyValue::Sidekiq do
    let(:subject) { described_class.new }

    it 'appends sidekiq context to string message' do
      expect(subject.call(:info, nil, 'dummy', 'string'))
        .to match(/^severity="info" appname="dummy" message="string" sidekiq.tid="[a-z0-9]{9}"\n$/m)
    end

    it 'appends sidekiq context to string formatted message' do
      Thread.current[:sidekiq_context] = { key: :value1 }
      expect(subject.call(:info, nil, 'dummy', 'key="value"'))
        .to match(/^severity="info" appname="dummy" key="value" sidekiq.key="value1" sidekiq.tid="[a-z0-9]{9}"\n$/m)
    ensure
      Thread.current[:sidekiq_context] = nil
    end

    it 'appends sidekiq context to hash messages' do
      Thread.current[:sidekiq_context] = { key: :value2 }
      expect(subject.call(:info, nil, 'dummy', key: :value ))
        .to match(/^severity="info" appname="dummy" key="value" sidekiq.key="value2" sidekiq.tid="[a-z0-9]{9}"\n$/m)
    ensure
      Thread.current[:sidekiq_context] = nil
    end
  end

  describe GetaroundUtils::LogFormatters::DeepKeyValue::Lograge do
    let(:subject) { described_class.new }

    it 'only takes one parametter' do
      expect(subject.call('string')).to eq('"string"')
      expect(subject.call(['a'])).to eq('0="a"')
      expect(subject.call(key: :value)).to eq('key="value"')
    end
  end
end
