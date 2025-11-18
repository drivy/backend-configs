# frozen_string_literal: true

require 'uri'

module GetaroundUtils; end

module GetaroundUtils::Utils; end

module GetaroundUtils::Utils::ConfigUrl
  def self.from_env(config_name, ...)
    env_url = ENV.fetch("#{config_name}_URL", ...)
    env_pwd = ENV.fetch("#{config_name}_PASSWORD", nil)
    return if env_url.nil?

    ::URI.parse(env_url).tap do |uri|
      if env_pwd && !uri.userinfo
        uri.userinfo = ":#{env_pwd}"
      elsif env_pwd
        uri.password ||= env_pwd
      end
    end
  end
end
