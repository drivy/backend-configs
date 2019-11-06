require 'rails/railtie'
require 'getaround_utils/log_formatters/deep_key_value'

module GetaroundUtils; end
module GetaroundUtils::Railties; end

class GetaroundUtils::Railties::KeyValueLogTags < Rails::Railtie
  module TaggedLoggingFormatterKeyValueLogTags
    def tags_text
      @tags_text ||= "#{current_tags.join(' ')} " if current_tags.any?
    end
  end

  module RackLoggerKeyValueLogTags
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

  initializer 'getaround_utils.action_controller' do
    ActiveSupport::TaggedLogging::Formatter.prepend TaggedLoggingFormatterKeyValueLogTags
    Rails::Rack::Logger.prepend RackLoggerKeyValueLogTags
  end
end
