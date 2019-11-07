require 'rails_helper'
require 'getaround_utils/patches/key_value_log_tags'

describe GetaroundUtils::Patches::KeyValueLogTags do
  described_class.enable

  let(:output) { Tempfile.new }
  let(:logger) { ActiveSupport::TaggedLogging.new(Logger.new(output)) }

  describe ActiveSupport::TaggedLogging::Formatter do
    it 'does nothing in the absence of tags' do
      logger.error('string01')
      output.rewind
      expect(output.read).to eq("string01\n")
    end

    it 'insert tags without encolsing them in brackets' do
      logger.tagged(['tag01', 'tag02']) { |logger| logger.error('string02') }
      output.rewind
      expect(output.read).to eq("tag01 tag02 string02\n")
    end
  end

  describe Rails::Rack::Logger do
    let(:app) do
      lambda { |_env| logger.error('something'); [200, {}, ['OK']] }
    end

    it 'logs a simple String tag' do
      middleware = described_class.new(app, ['tag01'])
      allow(middleware).to receive(:logger).and_return(logger)

      middleware.call(Rack::MockRequest.env_for("http://test.com"))
      output.rewind
      expect(output.read).to eq("tag01=\"tag01\" something\n")
    end

    it 'logs a simple Symbol tag' do
      middleware = described_class.new(app, [:host])
      allow(middleware).to receive(:logger).and_return(logger)

      middleware.call(Rack::MockRequest.env_for("http://test.com"))
      output.rewind
      expect(output.read).to eq("host=\"test.com\" something\n")
    end

    it 'logs a simple Proc tag' do
      middleware = described_class.new(app, [ ->(_request) { { key: "value" } }])
      allow(middleware).to receive(:logger).and_return(logger)

      middleware.call(Rack::MockRequest.env_for("http://test.com"))
      output.rewind
      expect(output.read).to eq("key=\"value\" something\n")
    end
  end
end
