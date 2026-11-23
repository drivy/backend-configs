# frozen_string_literal: true

require 'getaround_utils/exposed_hosts/entry'

module GetaroundUtils; end

module GetaroundUtils::ExposedHosts; end

# Matches the requests whose host is the host of one of the entries, in any case and with any port,
# e.g. `HostConstraint.new(configuration.entries(:internal, group: 'api'))`. An internal entry is matched against the
# raw Host header, ignoring X-Forwarded-Host and Forwarded. An external entry is matched against `request.host`: the
# forwarded host if any, else the Host header, else SERVER_NAME. That of the ActionDispatch::Request the router passes
# only reads X-Forwarded-Host, while that of a Rack::Request also reads Forwarded, before X-Forwarded-Host. An empty
# list matches no request.
# A routing constraint, which also takes any Rack::Request.
class GetaroundUtils::ExposedHosts::HostConstraint
  def initialize(entries)
    unless entries.is_a?(Array) && entries.all?(GetaroundUtils::ExposedHosts::Entry)
      raise ArgumentError, "expected a list of entries, got #{entries.inspect}"
    end

    @internal_entries, @external_entries = entries.partition(&:internal?).each(&:freeze)
  end

  # A request without a Host header matches no internal entry, but still matches an external entry on its forwarded
  # host or its SERVER_NAME.
  def matches?(request)
    internal_request?(request) || external_request?(request)
  end

  private

  def internal_request?(request)
    return false if @internal_entries.empty?

    host = request.host_authority
    @internal_entries.any? { |entry| entry.match?(host:) }
  end

  def external_request?(request)
    return false if @external_entries.empty?

    host = request.host
    @external_entries.any? { |entry| entry.match?(host:) }
  end
end
