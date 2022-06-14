# frozen_string_literal: true

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

  def loggable_logger_fallback
    @loggable_logger_fallback ||= Logger.new($stdout)
  end

  def loggable_logger
    (logger if respond_to?(:logger)) || (Rails.logger if defined?(Rails)) || loggable_logger_fallback
  end

  def loggable_log(severity, message, payload = {})
    base_append_infos_to_loggable(payload)
    loggable_logger.send(severity.to_sym, msg: message, **payload)
  end

  MONITORABLE_LOG_PREFIX = "monitorable_log__"

  def monitorable_log(event_name, **options)
    monitorable_threshold = monitorable_threshold(event_name)
    return if monitorable_threshold.blank?

    loggable_log(
      :info,
      log_message(event_name),
      alert_threshold: monitorable_threshold,
      **options
    )
  end

  def monitorable_threshold(event_name)
    monitorable_threshold = ENV["#{log_message(event_name)}_threshold".upcase]&.to_i
    if monitorable_threshold.nil? && rails_config_defined?
      monitorable_threshold = Rails.application.config.monitorable_log_thresholds&.dig(event_name.to_sym)
    end
    monitorable_threshold
  end

  def log_message(event_name)
    MONITORABLE_LOG_PREFIX + event_name
  end

  private

  def rails_config_defined?
    defined?(Rails) &&
      Rails.application.config.respond_to?(:monitorable_log_thresholds) &&
      Rails.application.config.monitorable_log_thresholds.respond_to?(:dig)
  end
end
