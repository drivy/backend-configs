require 'logger'
module GetaroundUtils; end
module GetaroundUtils::Mixins; end

module GetaroundUtils::Mixins::Loggable
  def class_name
    @class_name ||= is_a?(Class) ? name : self.class.name
  end

  def base_append_infos_to_loggable(payload)
    payload[:origin] = class_name
    return unless respond_to?(:append_infos_to_loggable)

    append_infos_to_loggable(payload)
  end

  def base_loggable_logger
    @base_loggable_logger ||= if respond_to?(:logger)
      logger
    elsif defined?(Rails)
      Rails.logger
    else
      Logger.new(STDOUT)
    end
  end

  def loggable_formatter
    @loggable_formatter ||= GetaroundUtils::Utils::DeepKeyValueSerializer.new
  end

  def loggable(severity, message)
    payload = {}
    base_append_infos_to_loggable(payload)
    message = if message.is_a?(Hash)
      loggable_formatter.serialize(message.merge(payload).compact)
    else
      "#{loggable_formatter.serialize(payload)} #{message}"
    end
    base_loggable_logger.send(severity.to_sym, message)
  end
end
