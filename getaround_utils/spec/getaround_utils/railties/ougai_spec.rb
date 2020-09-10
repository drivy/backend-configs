require 'sidekiq'
require 'rails_helper'


describe GetaroundUtils::Railties::Ougai do

  describe 'via Rails' do
    it 'setup a child logger as the Rails logger' do
      expect(Rails.logger).to be_a(OugaiRailsLogger)
    end

    describe 'uses GetaroundUtils::Ougai::DeepKeyValuesFormatter by default' do
      it 'setup a child logger as the Rails logger' do
        expect(Rails.logger.formatter).to be_a(GetaroundUtils::Ougai::DeepKeyValuesFormatter)
      end
    end

    it 'forwards simple log params to the formatter' do
      expect(Rails.application.config.ougai_logger.formatter).to receive(:call)
        .with("ERROR", kind_of(Time), nil, msg: 'message')
      Rails.logger.error('message')
    end

    it 'forwards structured log params to the formatter' do
      expect(Rails.application.config.ougai_logger.formatter).to receive(:call)
        .with("ERROR", kind_of(Time), nil, key: :value, msg: 'message')
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
      allow(RequestStore.store).to receive(:[])
        .and_call_original
      expect(RequestStore.store).to receive(:[]).with(:ougai)
        .and_return(request_id: 'test')
      expect(Rails.application.config.ougai_logger.formatter).to receive(:call)
        .with("INFO", kind_of(Time), nil, hash_including(method: 'GET', request_id: 'test'))
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
      allow(RequestStore.store).to receive(:[])
        .and_call_original
      expect(RequestStore.store).to receive(:[]).with(:ougai)
        .and_return(request_id: 'test')
      expect(Rails.application.config.ougai_logger.formatter).to receive(:call)
        .with("WARN", kind_of(Time), nil, key: :value, msg: 'message', request_id: 'test')
      controller.log_message
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

    it 'is setup as the default sidekiq logger' do
      expect(Sidekiq.logger).to be_a(OugaiRailsLogger)
    end

    it 'includes the extra data from the sidekiq context' do
      allow(Thread.current).to receive(:[])
        .and_call_original
      expect(Thread.current).to receive(:[]).with(:sidekiq_context)
        .and_return(job_id: 'test')

      expect(Rails.application.config.ougai_logger.formatter).to receive(:call)
        .with("WARN", kind_of(Time), nil, key: :value, msg: 'message', sidekiq: { job_id: 'test' })
      worker.new.perform
    end
  end
end
