require 'getaround_utils/utils/deep_key_value_serializer'

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
    def tags_text
      "#{current_tags.join(' ')} " if current_tags.any?
    end
  end

  module RackLogger
    def kv_formatter
      @kv_formatter ||= GetaroundUtils::Utils::DeepKeyValueSerializer.new
    end

    def compute_tags(request)
      @taggers.collect do |tag|
        case tag
        when Proc
          kv_formatter.serialize(tag.call(request))
        when Symbol
          kv_formatter.serialize(tag => request.send(tag))
        else
          kv_formatter.serialize(tag)
        end
      end
    end
  end

  def self.enable
    ActiveSupport::TaggedLogging::Formatter.prepend TaggedLoggingFormatter
    Rails::Rack::Logger.prepend RackLogger
  end
end
