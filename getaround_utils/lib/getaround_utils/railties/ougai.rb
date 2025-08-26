# frozen_string_literal: true

require 'getaround_utils/ougai/json_formatter'
require 'request_store'
require 'rails/railtie'
require 'ougai'

module GetaroundUtils; end

module GetaroundUtils::Railties; end

# Rails-compatible Ougai Logger
# https://github.com/tilfin/ougai/wiki/Use-as-Rails-logger#define-a-custom-logger
class OugaiRailsLogger < Ougai::Logger
  include ActiveSupport::LoggerThreadSafeLevel
  include ActiveSupport::LoggerSilence

  def initialize(*args)
    super
    after_initialize if respond_to?(:after_initialize) && ActiveSupport::VERSION::MAJOR < 6
  end
end

# Patch for ActiveSupport::TaggedLogging
# https://github.com/tilfin/ougai/wiki/Use-as-Rails-logger#with-activesupporttaggedlogging
module OugaiTaggedLoggingFormatter
  def call(severity, time, progname, data)
    if is_a?(Ougai::Formatters::Base)
      data = { msg: data.to_s } unless data.is_a?(Hash)
      data[:tags] = current_tags if current_tags.any?
      _call(severity, time, progname, data)
    else
      super
    end
  end
end

# Custom middleware to persist request metadatas
# https://github.com/tilfin/ougai/issues/73#issuecomment-475866224
# https://github.com/tilfin/ougai/issues/107#issuecomment-636050223
class OugaiRequestStoreMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    RequestStore.store[:ougai] = { http: { request_id: env['action_dispatch.request_id'] } }
    @app.call(env)
  end
end

class GetaroundUtils::Railties::Ougai < Rails::Railtie
  config.ougai_logger = OugaiRailsLogger.new($stdout)
  config.ougai_logger.formatter = GetaroundUtils::Ougai::JsonFormatter.new

  config.ougai_logger.before_log = lambda do |data|
    data.deep_merge!(RequestStore.store[:ougai]) \
      if defined?(RequestStore) && RequestStore.store.key?(:ougai)

    data.merge!(sidekiq: Thread.current[:sidekiq_context]) \
      if defined?(Sidekiq) && Thread.current.key?(:sidekiq_context)
  end

  initializer :getaround_utils_ougai, before: :initialize_logger do |app|
    app.config.logger = config.ougai_logger
  end

  initializer :getaround_utils_ougai_middleware do |app|
    app.config.app_middleware.insert_after(ActionDispatch::RequestId, OugaiRequestStoreMiddleware)
  end

  initializer :getaround_utils_ougai_activesupport do
    ActiveSupport::TaggedLogging::Formatter.prepend(OugaiTaggedLoggingFormatter)
  end

  initializer :getaround_utils_ougai_lograge do |app|
    next unless defined?(Lograge)

    # https://github.com/tilfin/ougai/wiki/Use-as-Rails-logger#with-lograge
    app.config.lograge.logger = app.config.logger
    app.config.lograge.formatter = Lograge::Formatters::Raw.new
  end

  initializer :getaround_utils_ougai_sidekiq do
    next unless defined?(Sidekiq)

    # https://github.com/tilfin/ougai/wiki/Customize-Sidekiq-logger
    Sidekiq.configure_client do |config|
      config.logger = Rails.application.config.logger
    end

    Sidekiq.configure_server do |config|
      config.logger = Rails.application.config.logger

      original_handler = config.error_handlers.shift
      # Third argument "config" was introduced in 7.x, enforced in 8.x
      config.error_handlers << lambda do |ex, ctx, _config = nil|
        if Sidekiq.logger.is_a?(Ougai::Logger)
          Sidekiq.logger.warn(ex, job: ctx[:job])
        else
          original_handler.call(ex, ctx)
        end
      end
    end
  end
end
