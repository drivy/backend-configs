# frozen_string_literal: true

require 'getaround_utils/exposed_hosts/host_constraint'

module GetaroundUtils; end

module GetaroundUtils::ExposedHosts; end

module GetaroundUtils::ExposedHosts::RoutingHelpers
  def default_host(visibility = nil, **metadata, &)
    raise ArgumentError, 'requires visibility or metadata for filtering' if visibility.nil? && metadata.empty?

    url_options = Rails.application.config.exposed_hosts.entry(visibility, **metadata).url_options
    defaults(**url_options, &)
  end

  def host_constraint(visibility = nil, **metadata, &)
    raise ArgumentError, 'requires visibility or metadata for filtering' if visibility.nil? && metadata.empty?

    entries = Rails.application.config.exposed_hosts.entries(visibility, **metadata)
    constraints(GetaroundUtils::ExposedHosts::HostConstraint.new(entries), &)
  end

  def private_routes(**metadata, &)
    host_constraint(:private, **metadata) do
      default_host(:private, **metadata, &)
    end
  end
end
