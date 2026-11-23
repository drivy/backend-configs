# frozen_string_literal: true

require 'getaround_utils/exposed_hosts/host_constraint'

module GetaroundUtils; end

module GetaroundUtils::ExposedHosts; end

# Added to the routes DSL by GetaroundUtils::Railties::ExposedHosts.
# `internal_routes` and `host_defaults` reserve `params[:host]`, which they set to the host of their entry whatever the
# request says.
module GetaroundUtils::ExposedHosts::RoutingHelpers
  # Routes that only exist on the hosts whose entry has the exposure and matches the other criteria, e.g.
  # `host_constraints(:internal, group: 'api')`. It takes the arguments of `Configuration#entries`: without exposure,
  # on every declared host whose entry matches the criteria, and without any criterion, on every declared host. Raises
  # an ArgumentError for an exposure that `Configuration#entries` refuses, an UndeclaredHost when no entry matches.
  # Unlike `internal_routes`, it neither sets `params[:host]` nor picks the host of their URLs. For that, wrap them in a
  # `host_defaults` whose host is one of these hosts, or their URLs point to a host where they do not answer, e.g.
  # `host_constraints(group: 'api') { host_defaults(:external, group: 'api') { ... } }`.
  def host_constraints(*, **, &)
    entries = Rails.configuration.exposed_hosts.entries(*, **)
    constraints(GetaroundUtils::ExposedHosts::HostConstraint.new(entries), &)
  end

  # Routes whose URLs are generated on the host of the first entry that has the exposure and matches the other
  # criteria, e.g. `host_defaults(:external, group: 'api')`. Their other URL options, e.g. a protocol or a port, still
  # come from the `default_url_options` of the routes.
  # They answer on every host. Takes the arguments of `Configuration#entry`, and raises an ArgumentError for an
  # exposure that it refuses, an UndeclaredHost when no entry matches.
  def host_defaults(*, **, &)
    entry = Rails.configuration.exposed_hosts.entry(*, **)
    defaults(host: entry.host, &)
  end

  # Routes that only exist on the internal hosts, and whose URLs are generated on the first of them.
  # With criteria, those of `Configuration#entries` but the exposure, only the internal hosts whose entry matches them,
  # e.g. `internal_routes(group: 'api')`. An `exposure` among them raises an ArgumentError.
  def internal_routes(**, &)
    host_constraints(:internal, **) do
      host_defaults(:internal, **, &)
    end
  end
end
