require 'spec_helper'

describe GetaroundUtils::Patches::KeyValueLogTags do
  before do
    stub_formatter = Module.new { include ActiveSupport::TaggedLogging::Formatter }
    stub_formatter.prepend(GetaroundUtils::Patches::KeyValueLogTags::TaggedLoggingFormatter)
    stub_const('ActiveSupport::TaggedLogging::Formatter', stub_formatter)

    stub_logger = Class.new(Rails::Rack::Logger)
    stub_logger.prepend(GetaroundUtils::Patches::KeyValueLogTags::RackLogger)
    stub_const('Rails::Rack::Logger', stub_logger)
  end

  let(:output) { Tempfile.new }
  let(:logger) { ActiveSupport::TaggedLogging.new(Logger.new(output)) }

  describe 'ActiveSupport::TaggedLogging::Formatter' do
    it 'does nothing in the absence of tags' do
      expect(output).to receive(:write)
        .with("string01\n")
      logger.error('string01')
    end

    it 'insert tags without encolsing them in brackets' do
      expect(output).to receive(:write)
        .with("tag01 tag02 string02\n")
      logger.tagged(['tag01', 'tag02']) { |logger| logger.error('string02') }
    end
  end

  describe 'Rails::Rack::Logger' do
    let(:app) do
      lambda { |_env| logger.error('something'); [200, {}, ['OK']] }
    end

    it 'logs a String tag' do
      middleware = Rails::Rack::Logger.new(app, ['tag01'])
      allow(middleware).to receive(:logger).and_return(logger)

      expect(output).to receive(:write)
        .with("\"tag01\" something\n")
      middleware.call(Rack::MockRequest.env_for("http://test.com"))
    end

    it 'logs a Symbol tag' do
      middleware = Rails::Rack::Logger.new(app, [:host])
      allow(middleware).to receive(:logger).and_return(logger)

      expect(output).to receive(:write)
        .with("host=\"test.com\" something\n")
      middleware.call(Rack::MockRequest.env_for("http://test.com"))
    end

    it 'logs a Proc tag' do
      middleware = Rails::Rack::Logger.new(app, [ ->(_request) { { key: "value" } }])
      allow(middleware).to receive(:logger).and_return(logger)

      expect(output).to receive(:write)
        .with("key=\"value\" something\n")
      middleware.call(Rack::MockRequest.env_for("http://test.com"))
    end
  end
end
