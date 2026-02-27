# frozen_string_literal: true

require "active_support"
require 'i18n/backend/transliterator'
require "i18n/backend/simple"

module GetaroundUtils; end
module GetaroundUtils::I18nBackend; end

class GetaroundUtils::I18nBackend::FlatKeys < I18n::Backend::Simple
  def store_translations(locale, data, options = {})
    expanded = expand_dot_keys(data)
    super(locale, expanded, options)
  end

  private

  def expand_dot_key(path, value)
    if path.any?
      { path.first.to_sym => expand_dot_key(path[1...], value) }
    else
      value
    end
  end

  def expand_dot_keys(data)
    data.each_with_object({}) do |(key, value), acc|
      hash = expand_dot_key([*key.to_s.split(".")], value)
      acc.deep_merge!(hash)
    end
  end
end
