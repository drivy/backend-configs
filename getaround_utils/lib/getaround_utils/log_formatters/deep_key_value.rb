module GetaroundUtils; end
module GetaroundUtils::LogFormatters; end

require 'getaround_utils/utils/deep_key_value'

class GetaroundUtils::LogFormatters::DeepKeyValue
  module Shared
    def normalize(message)
      if message.is_a?(Hash)
        GetaroundUtils::Utils::DeepKeyValue.serialize(message.compact)
      elsif message.is_a?(String) && message.match(/^[^ =]+=/)
        message
      else
        GetaroundUtils::Utils::DeepKeyValue.serialize(message: message.to_s)
      end
    end
  end

  class Base
    include GetaroundUtils::LogFormatters::DeepKeyValue::Shared

    def call(severity, _datetime, appname, message)
      payload = { severity: severity, appname: appname }
      "#{normalize(payload)} #{normalize(message)}\n"
    end
  end

  def self.new
    Base.new
  end

  class Lograge
    def call(message)
      message = message.compact if message.is_a?(Hash)
      GetaroundUtils::Utils::DeepKeyValue.serialize(message)
    end
  end

  def self.for_lograge
    Lograge.new
  end

  class Sidekiq < Base
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
    Sidekiq.new
  end
end
