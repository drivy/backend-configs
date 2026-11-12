# frozen_string_literal: true

require 'getaround_utils/exposed_hosts/host_constraint'

module GetaroundUtils; end

module GetaroundUtils::ExposedHosts; end

# Added to the routes DSL by GetaroundUtils::Railties::ExposedHosts.
# `private_routes` and `default_host` reserve a param per key of the `url_options` of their entry, which they set
# whatever the request says: `params[:host]`, and one per key of its `default_url_options`.
module GetaroundUtils::ExposedHosts::RoutingHelpers
  # Routes whose URLs are generated on the host of the first entry that has the visibility and matches the metadata,
  # e.g. `default_host(:public, group: 'api')`, with the `url_options` of that entry. The options it does not set, e.g.
  # a port, still come from the `default_url_options` of the routes. Without visibility, the first entry matching the
  # metadata, whatever its visibility.
  # They answer on every host. Raises an ArgumentError without visibility nor metadata, a KeyError when no entry
  # matches.
  def default_host(visibility = nil, **metadata, &)
    raise ArgumentError, 'requires visibility or metadata for filtering' if visibility.nil? && metadata.empty?

    url_options = Rails.application.config.exposed_hosts.entry(visibility, **metadata).url_options
    defaults(**url_options, &)
  end

  # Routes that only exist on the hosts whose entry has the visibility and matches the metadata, e.g.
  # `host_constraint(:private, group: 'api')`. Without visibility, on every declared host whose entry matches the
  # metadata. Raises an ArgumentError without visibility nor metadata, a KeyError when no entry matches.
  # Unlike `private_routes`, it neither sets the params of the URL options nor picks the host of their URLs: wrap them
  # in `default_host` with the same metadata for that, e.g.
  # `host_constraint(group: 'api') { default_host(:public, group: 'api') { ... } }`.
  def host_constraint(visibility = nil, **metadata, &)
    raise ArgumentError, 'requires visibility or metadata for filtering' if visibility.nil? && metadata.empty?

    entries = Rails.application.config.exposed_hosts.entries(visibility, **metadata)
    constraints(GetaroundUtils::ExposedHosts::HostConstraint.new(entries), &)
  end

  # Routes that only exist on the private hosts, and whose URLs are generated on the first of them.
  # With metadata, only the private hosts whose entry matches it, e.g. `private_routes(group: 'api')`.
  def private_routes(**metadata, &)
    host_constraint(:private, **metadata) do
      default_host(:private, **metadata, &)
    end
  end
end
