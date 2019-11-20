require "spec_helper"

describe GetaroundUtils::LogFormatters::DeepKeyValue do
  describe '.for_lograge' do
    let(:formatter) { described_class.for_lograge }

    it 'return a formatter variant that only takes one parametter' do
      expect(formatter.call('string')).to eq('"string"')
      expect(formatter.call(['a'])).to eq('0="a"')
      expect(formatter.call(key: :value)).to eq('key="value"')
    end
  end

  describe '.for_sidekiq' do
    let(:formatter) { described_class.for_sidekiq }

    it 'return a formatter variant that appends sidekiq context to string message' do
      expect(formatter.call(:info, nil, 'dummy', 'string'))
        .to match(%r{^severity="info" appname="dummy" message="string" sidekiq.tid="[a-z0-9]{9}"\n$}m)
    end

    it 'return a formatter variant that appends sidekiq context to string formatted message' do
      Thread.current[:sidekiq_context] = { key: :value1 }
      expect(formatter.call(:info, nil, 'dummy', 'key="value"'))
        .to match(%r{^severity="info" appname="dummy" key="value" sidekiq.key="value1" sidekiq.tid="[a-z0-9]{9}"\n$}m)
    ensure
      Thread.current[:sidekiq_context] = nil
    end

    it 'return a formatter variant that appends sidekiq context to hash messages' do
      Thread.current[:sidekiq_context] = { key: :value2 }
      expect(formatter.call(:info, nil, 'dummy', key: :value ))
        .to match(%r{^severity="info" appname="dummy" key="value" sidekiq.key="value2" sidekiq.tid="[a-z0-9]{9}"\n$}m)
    ensure
      Thread.current[:sidekiq_context] = nil
    end
  end

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
