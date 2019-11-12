require "spec_helper"

describe GetaroundUtils::LogFormatters::DeepKeyValue do
  describe '.for_lograge' do
    it 'return a formatter variant that only takes one parametter' do
      formatter = described_class.for_lograge
      expect(formatter.call('string')).to eq('"string"')
      expect(formatter.call(['a'])).to eq('0="a"')
      expect(formatter.call(key: :value)).to eq('key="value"')
    end
  end

  describe '.for_sidekiq' do
    it 'return a formatter variant that appends sidekiq context to string message' do
      formatter = described_class.for_sidekiq

      Thread.current['sidekiq_tid'] = 'whatever'
      Thread.current[:sidekiq_context] = { key: :value }
      expect(formatter.call(:info, nil, 'dummy', 'string'))
        .to match(/^severity="info" appname="dummy" message="string" sidekiq.tid="whatever" sidekiq.key="value"\n$/)
    end

    it 'return a formatter variant that appends sidekiq context to hash messages' do
      formatter = described_class.for_sidekiq

      Thread.current['sidekiq_tid'] = 'whatever'
      Thread.current[:sidekiq_context] = { key: :value }
      expect(formatter.call(:info, nil, 'dummy', key: :value ))
        .to match(/^severity="info" appname="dummy" key="value" sidekiq.tid="whatever" sidekiq.key="value"\n$/)
    end
  end

  context 'when using via a Logger' do
    let(:output) do
      Tempfile.new
    end

    let :logger do
      logger = Logger.new(output)
      logger.formatter = subject
      logger
    end

    it 'works with hash' do
      expect(output).to receive(:write)
        .with(/^severity="INFO" message="string"\n$/)
      logger.info('string')
    end

    it 'works with progname' do
      expect(output).to receive(:write)
        .with(/^severity="INFO" appname="dummy" message="string"\n$/)
      logger.info('dummy') { 'string' }
    end

    it 'works with Hashes' do
      expect(output).to receive(:write)
        .with(/^severity="INFO" key="value" message="string"\n$/)
      logger.info(key: 'value', message: 'string')
    end
  end
end
