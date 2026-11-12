# frozen_string_literal: true

require 'rails/railtie'
require 'getaround_utils/exposed_hosts/configuration'
require 'getaround_utils/exposed_hosts/routing_helpers'

module GetaroundUtils; end

module GetaroundUtils::Railties; end

class GetaroundUtils::Railties::ExposedHosts < Rails::Railtie
  # Runs as soon as the application class is defined, so that its body and its environment files can read the hosts.
  config.before_configuration do |app|
    app.config.exposed_hosts = GetaroundUtils::ExposedHosts::Configuration.new(app.config_for(:exposed_hosts))
  end

  # Runs before the routes are drawn, so that they can use `private_routes`, `default_host` and `host_constraint`.
  initializer 'getaround_utils.exposed_hosts.routing_helpers' do
    ActionDispatch::Routing::Mapper.include(GetaroundUtils::ExposedHosts::RoutingHelpers)
  end
end
