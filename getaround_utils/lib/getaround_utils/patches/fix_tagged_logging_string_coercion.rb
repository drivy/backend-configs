require 'rails/railtie'
module GetaroundUtils; end
module GetaroundUtils::Patches; end

##
# Fixes the ActiveSupport::TaggedLogging::Formatter string coercion
#
# Ruby Logger and child classes don't necessarilly expect message to be string.
# In theory, they should preserve the message value intact until it is passed to the formatter.
#
# ActiveSupport::TaggedLogging breaks this by injecting the tags via string concatenation,
# which coerces messages of any type into String.
# This patches works around this by instead appending the tags to the result of the
# original formatter result, which is garanteed to be a string

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
