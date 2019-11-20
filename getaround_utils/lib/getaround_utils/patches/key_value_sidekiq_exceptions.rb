require 'sidekiq/exception_handler'
require 'getaround_utils/utils/deep_key_value_serializer'

module GetaroundUtils; end
module GetaroundUtils::Patches; end

class GetaroundUtils::Patches::KeyValueSidekiqExceptions
  module ExceptionHandlerLogger
    def kv_formatter
      @kv_formatter ||= GetaroundUtils::Utils::DeepKeyValueSerializer.new
    end

    def call(exception, ctx)
      payload = {}
      payload[:message] = exception.message
      payload[:exception] = exception.class.name
      payload[:backtrace] = exception.backtrace&.join("\n")
      payload[:sidekiq] = ctx
      Sidekiq.logger.warn(kv_formatter.serialize(payload.compact))
    end
  end

  def self.enable
    Sidekiq::ExceptionHandler::Logger.prepend ExceptionHandlerLogger
  end
end
