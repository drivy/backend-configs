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
    @base_loggable_logger ||= if respond_to?(:logger) && !logger.nil?
      logger
    elsif defined?(Rails)
      Rails.logger
    else
      Logger.new(STDOUT)
    end
  end

  def loggable(severity, message, payload = {})
    base_loggable_logger.send(
      :warn,
      "Deprecated usage of GetaroundUtils::Mixins::Loggable#loggable(*args). Please use GetaroundUtils::Mixins::Loggable#loggable_log(*args) instead"
    )
    loggable_log(severity, message, payload)
  end

  def loggable_log(severity, message, payload = {})
    base_append_infos_to_loggable(payload)
    base_loggable_logger.send(severity.to_sym, msg: message, **payload)
  end
end
