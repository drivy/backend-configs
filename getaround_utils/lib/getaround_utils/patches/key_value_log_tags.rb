require 'getaround_utils/log_formatters/deep_key_value'

module GetaroundUtils; end
module GetaroundUtils::Patches; end

##
# Augment the ActiveRecord::TaggedLogging tag formatting
#
# Tags are defined either as String, Proc or a property of request
#
# Originally they will be formatted as `[tag_value]`
# This patch will instead attempt to serialize the tag with GetaroundUtils::DeepKeyValueSerializer
#
# ie:
#  - for a String `value` it would yield `"value"`
#  - for a Symbol `:request_id` it would yield `request_id="request_id_value"`
#  - for a Proc `-> {key: :val}` it would yield `key="value"`

class GetaroundUtils::Patches::KeyValueLogTags
  module TaggedLoggingFormatter
    include GetaroundUtils::LogFormatters::DeepKeyValue::Shared

    def tags_text
      "#{current_tags.join(' ')} " if current_tags.any?
    end

    def call(severity, datetime, appname, message)
      original_method = method(__method__).super_method.super_method
      message = "#{tags_text}#{normalize(message)}"
      original_method.call(severity, datetime, appname, message)
    end
  end

  module RackLogger
    def compute_tags(request)
      @taggers.collect do |tag|
        case tag
        when Proc
          GetaroundUtils::Utils::DeepKeyValue.serialize(tag.call(request))
        when Symbol
          GetaroundUtils::Utils::DeepKeyValue.serialize(tag => request.send(tag))
        else
          GetaroundUtils::Utils::DeepKeyValue.serialize(tag)
        end
      end
    end
  end

  def self.enable
    ActiveSupport::TaggedLogging::Formatter.prepend TaggedLoggingFormatter
    Rails::Rack::Logger.prepend RackLogger
  end
end
