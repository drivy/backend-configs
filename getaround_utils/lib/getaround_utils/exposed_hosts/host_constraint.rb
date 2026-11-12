# frozen_string_literal: true

require 'getaround_utils/exposed_hosts/entry'

module GetaroundUtils; end

module GetaroundUtils::ExposedHosts; end

# Matches the requests whose raw Host header is the host of one of the entries, in any case and with any port,
# e.g. `HostConstraint.new(configuration.entries(:private, group: 'api'))`. It ignores `request.host`, which follows
# X-Forwarded-Host. A routing constraint, which also takes any Rack::Request.
class GetaroundUtils::ExposedHosts::HostConstraint
  def initialize(entries)
    raise ArgumentError, "expected a list of entries, got #{entries.inspect}" unless entries.is_a?(Array) && entries.all?(GetaroundUtils::ExposedHosts::Entry)
    raise ArgumentError, "expected at least one entry, got #{entries.inspect}" if entries.empty?

    @entries = entries.dup.freeze
  end

  # A request without a Host header, whose authority is nil, matches none.
  def matches?(request)
    authority = request.host_authority
    @entries.any? { |entry| entry.match?(host: authority) }
  end
end
