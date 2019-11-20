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
        .with(%{message="Dummy" exception="StandardError" backtrace="/file/dummy:0 in `block in call\\n/file/dummy:1 in `block in call"})
      logger.call(ex, {})
    end

    it 'logs the passed context' do
      ex = StandardError.new('Dummy')

      expect(Sidekiq.logger).to receive(:warn)
        .with(%{message="Dummy" exception="StandardError" sidekiq.key="value"})
      logger.call(ex, key: :value)
    end
  end
end
