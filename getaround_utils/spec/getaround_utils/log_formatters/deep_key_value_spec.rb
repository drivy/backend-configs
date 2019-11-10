require "spec_helper"

describe GetaroundUtils::LogFormatters::DeepKeyValue do
  describe '.serialize' do
    it 'serializes a flat hash with a simple string correctly' do
      expect(subject.serialize(key: 'value')).to eq('key="value"')
    end

    it 'serializes a flat hash with complex strings correctly' do
      expect(subject.serialize(key: 'This \ " is &\' weird one   ')).to eq('key="This \\\\ \\" is &\' weird one   "')
    end

    it 'serializes a flat hash with simple values correctly' do
      expect(subject.serialize(key: 42.0)).to eq('key=42.0')
    end

    it 'serializes a flat hash with complex values correctly' do
      expect(subject.serialize(key: Tempfile.new)).to match(/^key="#<File:.+>"$/)
    end

    it 'serializes a flat hash with simple array correctly' do
      expect(subject.serialize(key: ['a', 'b'])).to eq('key.0="a" key.1="b"')
    end

    it 'serializes a flat hash with complex array correctly' do
      expect(subject.serialize(key: ['a', 42, 55.123])).to eq('key.0="a" key.1=42 key.2=55.123')
    end

    it 'serializes a deep hash with a simple payload correctly' do
      expect(subject.serialize(key1: { key2: { key3: 'value' } })).to eq('key1.key2.key3="value"')
    end

    it 'serializes a deep hash with a complex payload correctly' do
      expect(subject.serialize(
        a1: { b1: { c2: 'value' }, b2: [1, 42.0] }, a2: { b1: 'fifty' }, a3: [{ b3: 'c4' }],
      )).to eq(
        'a1.b1.c2="value" a1.b2.0=1 a1.b2.1=42.0 a2.b1="fifty" a3.0.b3="c4"'
      )
    end

    it 'serializes a number correctly' do
      expect(subject.serialize(42)).to eq('42')
    end

    it 'serializes a nested number correctly' do
      expect(subject.serialize(value: 42)).to eq('value=42')
    end

    it 'serializes a string correctly' do
      expect(subject.serialize(' \ " ')).to eq('" \\\\ \" "')
    end

    it 'serializes a nested string correctly' do
      expect(subject.serialize(value: ' \ " ')).to eq('value=" \\\\ \" "')
    end

    it 'serializes an inspect-type string correctly' do
      expect(subject.serialize('" something "')).to eq('" something "')
    end

    it 'serializes a nested inspect-type string correctly' do
      expect(subject.serialize(value: '" something "')).to eq('value=" something "')
    end

    it 'serializes an object correctly' do
      expect(subject.serialize(value: Tempfile.new)).to match(/^value="#<File.+>"$/)
    end
  end

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
