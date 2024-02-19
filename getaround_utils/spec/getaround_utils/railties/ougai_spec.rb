# frozen_string_literal: true

require 'sidekiq'
require 'rails_helper'

describe GetaroundUtils::Railties::Ougai do
  describe 'via Rails' do
    it 'setup a child logger as the Rails logger' do
      expect(Rails.logger).to be_a(OugaiRailsLogger)
    end

    describe 'uses GetaroundUtils::Ougai::DeepKeyValueFormatter by default' do
      it 'setup a child logger as the Rails logger' do
        expect(Rails.logger.formatter).to be_a(GetaroundUtils::Ougai::JsonFormatter)
      end
    end

    it 'forwards simple log params to the formatter' do
      expect(Rails.application.config.ougai_logger.formatter).to receive(:call)
        .with("ERROR", kind_of(Time), nil, { msg: 'message' })
      Rails.logger.error('message')
    end

    it 'forwards structured log params to the formatter' do
      expect(Rails.application.config.ougai_logger.formatter).to receive(:call)
        .with("ERROR", kind_of(Time), nil, { key: :value, msg: 'message' })
      Rails.logger.error('message', key: :value)
    end
  end

  describe 'via lograge', type: :controller do
    controller(ActionController::Base) do
      def index; head :ok; end
    end

    it 'is setup as the default Lograge.logger' do
      expect(Lograge.logger).to be_a(OugaiRailsLogger)
    end

    it 'includes values from the RequestStore data hash' do
      allow(RequestStore).to receive(:store)
        .and_return(ougai: { http: { request_id: 'test' } })
      expect(Rails.application.config.ougai_logger.formatter).to receive(:call)
        .with("INFO", kind_of(Time), nil, hash_including(http: hash_including(method: 'GET', request_id: 'test')))
      get(:index)
    end
  end

  describe 'via ActionController', type: :controller do
    controller(ActionController::Base) do
      def log_message; logger.warn('message', key: :value); end
    end

    it 'is setup as the default ActionController.logger' do
      expect(controller.logger).to be_a(OugaiRailsLogger)
    end

    it 'includes the extra data from RequestStore' do
      allow(RequestStore).to receive(:store)
        .and_return(ougai: { http: { request_id: 'test' } })
      expect(Rails.application.config.ougai_logger.formatter).to receive(:call)
        .with("WARN", kind_of(Time), nil, { key: :value, msg: 'message', http: { request_id: 'test' } })
      controller.log_message
    end
  end

  describe 'via TaggedLogging' do
    it 'works for a classic logger' do
      log_message = -> {
        logger = ActiveSupport::TaggedLogging.new(Logger.new($stdout))
        logger.tagged('tag') { logger.warn('message') }
      }
      expect(log_message).to output("[tag] message\n").to_stdout
    end

    it 'insert tags to a ougai logger payload' do
      base_logger = OugaiRailsLogger.new($stdout)
      logger = ActiveSupport::TaggedLogging.new(base_logger)
      expect(logger.formatter).to receive(:_call)
        .with('WARN', kind_of(Time), nil, { msg: "message", tags: ["tag"] })
      logger.tagged('tag') { logger.warn('message') }
    end
  end

  describe 'via sidekiq', type: :request do
    let(:worker) {
      Class.new do
        include Sidekiq::Worker
        def perform
          logger.warn('message', key: :value)
        end
      end
    }

    around do |ex|
      Thread.current[:sidekiq_context] = { job_id: 'test' }
      ex.run
      Thread.current[:sidekiq_context] = nil
    end

    it 'is setup as the default sidekiq logger' do
      expect(Sidekiq.logger).to be_a(OugaiRailsLogger)
    end

    it 'includes the extra data from the sidekiq context' do
      expect(Rails.application.config.ougai_logger.formatter).to receive(:call)
        .with("WARN", kind_of(Time), nil, { key: :value, msg: 'message', sidekiq: { job_id: 'test' } })
      worker.new.perform
    end
  end
end
