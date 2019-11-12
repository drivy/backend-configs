module GetaroundUtils; end
module GetaroundUtils::LogFormatters; end

require 'getaround_utils/utils/deep_key_value_serializer'

##
# Format logs using key=value notation
#
# This logger leverage the fact that ruby Logger does not especially expect message to be string
# It will attempt to serialize message it is a string otherwise adding it as message=value

class GetaroundUtils::LogFormatters::DeepKeyValue < GetaroundUtils::Utils::DeepKeyValueSerializer
  def call(severity, _datetime, appname, message)
    payload = { severity: severity, appname: appname }
    if message.is_a?(Hash)
      "#{serialize(payload.merge(message).compact)}\n"
    else
      "#{serialize(payload.compact)} #{message}\n"
    end
  end

  module Lograge
    def call(data)
      data.compact! if data.is_a?(Hash)
      serialize(data)
    end
  end

  ##
  # Return a lograge-style LogFormatter
  #
  # This formatter will only take one argument and serialize it

  def self.for_lograge
    new.extend(Lograge)
  end

  module Sidekiq
    def call(severity, _datetime, appname, message)
      payload = {}
      payload[:sidekiq] = Thread.current[:sidekiq_context] || {}
      payload[:sidekiq][:tid] = Thread.current['sidekiq_tid']
      message = if message.is_a?(Hash)
        message.merge(payload.compact)
      else
        "#{serialize(payload.compact)} #{message}"
      end
      super
    end
  end

  ##
  # Return a sidekiq-style LogFormatter
  #
  # This formatter replicates the default Sidekiq LogFormatter behavior of merging context
  # values from the current Thread's store

  def self.for_sidekiq
    new.extend(Sidekiq)
  end
end
