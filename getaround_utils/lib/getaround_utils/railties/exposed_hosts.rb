# frozen_string_literal: true

require 'rails/railtie'
require 'getaround_utils/exposed_hosts/configuration'

module GetaroundUtils; end

module GetaroundUtils::Railties; end

class GetaroundUtils::Railties::ExposedHosts < Rails::Railtie
  config.before_configuration do |app|
    app.config.exposed_hosts = GetaroundUtils::ExposedHosts::Configuration.new(app.config_for(:exposed_hosts))
  end
end
