# frozen_string_literal: true

require 'uri'

module GetaroundUtils; end

module GetaroundUtils::Utils; end

module GetaroundUtils::Utils::ConfigUrl
  def self.from_env(config_name, ...)
    env_url = ENV.fetch("#{config_name}_URL", ...)
    env_usr = ENV.fetch("#{config_name}_USERNAME", nil)
    env_pwd = ENV.fetch("#{config_name}_PASSWORD", nil)
    return if env_url.nil? || env_url.empty? # rubocop:disable Rails/Blank

    ::URI.parse(env_url).tap do |uri|
      uri_usr, uri_pwd = uri.userinfo&.split(':', 2)
      uri_pwd = uri_pwd.to_s if uri.userinfo&.include?(':')
      usr = env_usr.nil? ? uri_usr : env_usr
      pwd = env_pwd.nil? ? uri_pwd : env_pwd
      userinfo = usr.to_s
      userinfo += ":#{pwd}" unless pwd.nil?

      uri.userinfo = userinfo unless userinfo.empty?
    end
  end
end
