require 'spec_helper'

describe GetaroundUtils::Patches::KeyValueSidekiqExceptions do
  before do
    stub_logger = Class.new(Sidekiq::ExceptionHandler::Logger)
    stub_logger.prepend(GetaroundUtils::Patches::KeyValueSidekiqExceptions::ExceptionHandlerLogger)
    stub_const('Sidekiq::ExceptionHandler::Logger', stub_logger)
  end

  let(:logger) { Sidekiq::ExceptionHandler::Logger.new }

  describe 'Sidekiq::ExceptionHandler::Logger' do
    it 'logs the passed exception' do
      ex = StandardError.new('Dummy')
      ex.set_backtrace(['/file/dummy:0 in `block in call', '/file/dummy:1 in `block in call'])

      expect(Sidekiq.logger).to receive(:warn)
        .with(%{exception="StandardError" message="Dummy" backtrace="/file/dummy:0 in `block in call\\n/file/dummy:1 in `block in call"})
      logger.call(ex, {})
    end

    it 'logs the passed context' do
      expect(Sidekiq.logger).to receive(:warn)
        .with(%{sidekiq.key="value"})
      logger.call(nil, key: :value)
    end
  end
end
