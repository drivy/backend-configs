require 'sidekiq/exception_handler'
require 'getaround_utils/utils/deep_key_value'

module GetaroundUtils; end
module GetaroundUtils::Patches; end

class GetaroundUtils::Patches::KeyValueSidekiqExceptions
  module ExceptionHandlerLogger
    def call(exception, ctx)
      payload = {}
      payload[:message] = exception.message
      payload[:exception] = exception.class.name
      payload[:backtrace] = exception.backtrace&.join("\n")
      payload[:sidekiq] = ctx
      Sidekiq.logger.warn(GetaroundUtils::Utils::DeepKeyValue.serialize(payload.compact))
    end
  end

  def self.enable
    Sidekiq::ExceptionHandler::Logger.prepend ExceptionHandlerLogger
  end
end
