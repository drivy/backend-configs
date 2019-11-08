require 'rails/railtie'
require 'getaround_utils/log_formatters/deep_key_value'

module GetaroundUtils; end
module GetaroundUtils::Patches; end

class GetaroundUtils::Patches::KeyValueLogTags
  module TaggedLoggingFormatter
    def tags_text
      "#{current_tags.join(' ')} " if current_tags.any?
    end
  end

  module RackLogger
    def compute_tags(request)
      @kv_formatter ||= GetaroundUtils::LogFormatters::DeepKeyValue.new
      @taggers.collect do |tag|
        case tag
        when Proc
          @kv_formatter.call(tag.call(request))
        when Symbol
          @kv_formatter.call(tag => request.send(tag))
        else
          @kv_formatter.call(tag => tag)
        end
      end
    end
  end

  def self.enable
    ActiveSupport::TaggedLogging::Formatter.prepend TaggedLoggingFormatter
    Rails::Rack::Logger.prepend RackLogger
  end
end
