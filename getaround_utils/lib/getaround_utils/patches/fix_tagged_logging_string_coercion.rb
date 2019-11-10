require 'rails/railtie'
module GetaroundUtils; end
module GetaroundUtils::Patches; end

class GetaroundUtils::Patches::FixTaggedLoggingStringCoercion
  module TaggedLoggingFormatter
    def fixed_tags_text
      " #{tags_text.strip}" if tags_text
    end

    def call(severity, datetime, appname, message)
      original_method = method(__method__).super_method.super_method
      payload = original_method.call(severity, datetime, appname, message)
      "#{payload.chomp}#{fixed_tags_text}\n"
    end
  end

  def self.enable
    ActiveSupport::TaggedLogging::Formatter.prepend TaggedLoggingFormatter
  end
end
