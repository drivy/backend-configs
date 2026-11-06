# frozen_string_literal: true

Rails.application.configure do
  config.x.private_host = config.exposed_hosts.private_host
  config.x.public_host = config.exposed_hosts.public_host

  config.action_dispatch.log_rescued_responses = false

  config.lograge.ignore_actions = ['LinksController#show']
end
