# frozen_string_literal: true

require 'getaround_utils/mixins/loggable'

module GetaroundUtils; end

module GetaroundUtils::Utils; end

module GetaroundUtils::Utils::HandleError
  extend GetaroundUtils::Mixins::Loggable

  # @see https://docs.bugsnag.com/platforms/ruby/rails/reporting-handled-errors/#sending-custom-diagnostics
  def self.notify_of(error, **metadata, &)
    if defined?(::Bugsnag)
      ::Bugsnag.notify(error) do |event|
        metadata.each do |name, value|
          if value.is_a?(Hash)
            event.add_metadata(name, value)
          else
            event.add_metadata('custom', name, value)
          end
        end
        yield event if block_given?
      end
    else
      loggable_log(
        :debug,
        'handled_error',
        error_class: error.class.name,
        error_message: error.to_s,
        **metadata
      )
    end
  end
end
