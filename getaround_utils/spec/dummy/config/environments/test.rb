# frozen_string_literal: true

Rails.application.configure do
  config.x.private_host = config.exposed_hosts.private_host
  config.x.public_host = config.exposed_hosts.public_host
end
