# frozen_string_literal: true

Rails.application.configure do
  # Read here to check that the hosts are loaded before the environment files.
  config.x.private_host = config.exposed_hosts.entry(:private).host
  config.x.public_host = config.exposed_hosts.entry(:public).host
end
