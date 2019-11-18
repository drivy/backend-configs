module GetaroundUtils; end
module GetaroundUtils::LogFormatters; end

require 'getaround_utils/utils/deep_key_value_serializer'

##
# Format logs using key=value notation
#
# This logger leverage the fact that ruby Logger does not especially expect message to be string
# It will attempt to serialize message it is a string otherwise adding it as message=value

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
    def call(severity, _datetime, appname, message)
      payload = { severity: severity, appname: appname }
      sidekiq = { sidekiq: Thread.current[:sidekiq_context] || {} }
      sidekiq[:sidekiq][:tid] = Thread.current['sidekiq_tid']
      "#{normalize(payload)} #{normalize(message)} #{normalize(sidekiq)}\n"
    end
  end

  def self.for_sidekiq
    new.extend(Sidekiq)
  end
end
