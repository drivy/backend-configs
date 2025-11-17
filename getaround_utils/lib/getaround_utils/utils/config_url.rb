# frozen_string_literal: true

require 'uri'

module GetaroundUtils; end

module GetaroundUtils::Utils; end

module GetaroundUtils::Utils::ConfigUrl
  def self.from_env(config_name, ...)
    env_url = ENV.fetch("#{config_name}_URL", ...)
    return if env_url.nil?

    env_pwd_key = "#{config_name}_PASSWORD"
    ::URI.parse(env_url).tap do |uri|
      uri.password ||= ENV.fetch(env_pwd_key) if ENV.key?(env_pwd_key)
    end
  end
end
