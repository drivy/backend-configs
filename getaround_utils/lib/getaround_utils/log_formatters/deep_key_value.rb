module GetaroundUtils; end
module GetaroundUtils::LogFormatters; end

require 'getaround_utils/utils/deep_key_value_serializer'

class GetaroundUtils::LogFormatters::DeepKeyValue < GetaroundUtils::Utils::DeepKeyValueSerializer
  def normalize(message)
    if message.is_a?(Hash)
      serialize(message.compact)
    elsif message.is_a?(String) && message.match(/^[^ =]+=/)
      message
    else
      serialize(message: message.to_s)
    end
  end

  def call(severity, _datetime, appname, message)
    payload = { severity: severity, appname: appname }
    "#{normalize(payload)} #{normalize(message)}\n"
  end

  module Lograge
    def call(message)
      message = message.compact if message.is_a?(Hash)
      serialize(message)
    end
  end

  def self.for_lograge
    new.extend(Lograge)
  end

  module Sidekiq
    def sidekiq_context
      context = Thread.current&.fetch(:sidekiq_context, nil)
      context.is_a?(Hash) ? context : {}
    end

    def sidekiq_tid
      Thread.current&.fetch('sidekiq_tid', nil) || (Thread.current&.object_id ^ ::Process.pid).to_s(36)
    end

    def call(severity, _datetime, appname, message)
      payload = { severity: severity, appname: appname }
      sidekiq = sidekiq_context.merge(tid: sidekiq_tid).compact
      "#{normalize(payload)} #{normalize(message)} #{normalize(sidekiq: sidekiq)}\n"
    end
  end

  def self.for_sidekiq
    new.extend(Sidekiq)
  end
end
