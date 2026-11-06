# frozen_string_literal: true

require 'getaround_utils/exposed_hosts/host_constraint'

module GetaroundUtils; end

module GetaroundUtils::ExposedHosts; end

# Added to the routes DSL by GetaroundUtils::Railties::ExposedHosts.
# `private_routes` and `host_defaults` reserve `params[:host]`, which they set to the host of their entry whatever the
# request says.
module GetaroundUtils::ExposedHosts::RoutingHelpers
  # Routes that only exist on the hosts whose entry has the visibility and matches the other criteria, e.g.
  # `host_constraints(:private, group: 'api')`. It takes the arguments of `Configuration#entries`: without visibility,
  # on every declared host whose entry matches the criteria, and without any criterion, on every declared host. Raises
  # an ArgumentError for a visibility that `Configuration#entries` refuses, an UndeclaredHost when no entry matches.
  # Unlike `private_routes`, it neither sets `params[:host]` nor picks the host of their URLs. For that, wrap them in a
  # `host_defaults` whose host is one of these hosts, or their URLs point to a host where they do not answer, e.g.
  # `host_constraints(group: 'api') { host_defaults(:public, group: 'api') { ... } }`.
  def host_constraints(*, **, &)
    entries = Rails.configuration.exposed_hosts.entries(*, **)
    constraints(GetaroundUtils::ExposedHosts::HostConstraint.new(entries), &)
  end

  # Routes whose URLs are generated on the host of the first entry that has the visibility and matches the other
  # criteria, e.g. `host_defaults(:public, group: 'api')`. Their other URL options, e.g. a protocol or a port, still
  # come from the `default_url_options` of the routes.
  # They answer on every host. Takes the arguments of `Configuration#entry`, and raises an ArgumentError for a
  # visibility that it refuses, an UndeclaredHost when no entry matches.
  def host_defaults(*, **, &)
    entry = Rails.configuration.exposed_hosts.entry(*, **)
    defaults(host: entry.host, &)
  end

  # Routes that only exist on the private hosts, and whose URLs are generated on the first of them.
  # With criteria, those of `Configuration#entries` but the visibility, only the private hosts whose entry matches them,
  # e.g. `private_routes(group: 'api')`. A `visibility` among them raises an ArgumentError.
  def private_routes(**, &)
    host_constraints(:private, **) do
      host_defaults(:private, **, &)
    end
  end
end
