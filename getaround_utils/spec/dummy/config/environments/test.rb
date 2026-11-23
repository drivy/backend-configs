# frozen_string_literal: true

Rails.application.configure do
  # Read here to check that the hosts are loaded before the environment files.
  config.x.internal_host = config.exposed_hosts.entry(:internal).host
  config.x.external_host = config.exposed_hosts.entry(:external).host

  # Keeps the routing errors of the specs that expect a 404 out of the suite's output.
  config.action_dispatch.log_rescued_responses = false

  # Keeps the requests of the routing specs, which LinksController answers, out of the suite's output.
  config.lograge.ignore_actions = ['LinksController#show']
end
