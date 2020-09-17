# frozen_string_literal: true

require 'getaround_utils/ougai/deep_key_value_formatter'
require 'request_store'
require 'rails/railtie'
require 'ougai'

module GetaroundUtils; end
module GetaroundUtils::Railties; end

# Rails-compatible Ougai Logger
# https://github.com/tilfin/ougai/wiki/Use-as-Rails-logger#define-a-custom-logger
class OugaiRailsLogger < Ougai::Logger
  include ActiveSupport::LoggerThreadSafeLevel
  include Rails::VERSION::MAJOR < 6 ? LoggerSilence : ActiveSupport::LoggerSilence
end

# Patch for ActiveSupport::TaggedLogging
# https://github.com/tilfin/ougai/wiki/Use-as-Rails-logger#with-activesupporttaggedlogging
module OugaiTaggedLoggingFormatter
  def call(severity, time, progname, data)
    data = { msg: data.to_s } unless data.is_a?(Hash)
    data[:tags] = current_tags if current_tags.any?
    _call(severity, time, progname, data)
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
    RequestStore.store[:ougai] = { request_id: env['action_dispatch.request_id'] }
    @app.call(env)
  end
end

class GetaroundUtils::Railties::Ougai < Rails::Railtie
  config.ougai_logger = OugaiRailsLogger.new(STDOUT)
  config.ougai_logger.after_initialize if Rails::VERSION::MAJOR < 6
  config.ougai_logger.formatter = GetaroundUtils::Ougai::DeepKeyValueFormatter.new
  config.ougai_logger.before_log = lambda do |data|
    request_store = RequestStore.store[:ougai] || {}
    data.merge!(request_store) if request_store&.any?

    sidekiq_context = Thread.current[:sidekiq_context] || {}
    data.merge!(sidekiq: sidekiq_context) if sidekiq_context&.any?
  end

  initializer :getaround_utils_ougai, before: :initialize_logger do |app|
    app.config.logger = config.ougai_logger
  end

  initializer :getaround_utils_ougai_middleware do |app|
    app.config.app_middleware.insert_after ActionDispatch::RequestId, OugaiRequestStoreMiddleware
  end

  initializer :getaround_utils_ougai_activesupport do
    ActiveSupport::TaggedLogging::Formatter.prepend OugaiTaggedLoggingFormatter
  end

  initializer :getaround_utils_ougai_lograge do |app|
    next unless defined?(Lograge)

    app.config.lograge.logger = app.config.logger
    app.config.lograge.formatter = Lograge::Formatters::Raw.new
  end

  initializer :getaround_utils_ougai_sidekiq do
    next unless defined?(Sidekiq)

    # https://github.com/tilfin/ougai/wiki/Customize-Sidekiq-logger
    Sidekiq.logger = config.ougai_logger

    Sidekiq.configure_server do |config|
      config.error_handlers.shift
      config.error_handlers << lambda do |ex, ctx|
        Sidekiq.logger.warn(ex, job: ctx[:job])
      end
    end
  end
end
