# frozen_string_literal: true

require 'getaround_utils/exposed_hosts/entry'

module GetaroundUtils; end

module GetaroundUtils::ExposedHosts; end

# Matches the requests whose host is the host of one of the entries, in any case and with any port,
# e.g. `HostConstraint.new(configuration.entries(:private, group: 'api'))`. A private entry is matched against the raw
# Host header, ignoring X-Forwarded-Host and Forwarded. A public entry is matched against `request.host`: the forwarded
# host if any, else the Host header, else SERVER_NAME. That of the ActionDispatch::Request the router passes only reads
# X-Forwarded-Host, while that of a Rack::Request also reads Forwarded, before X-Forwarded-Host. An empty list matches
# no request.
# A routing constraint, which also takes any Rack::Request.
class GetaroundUtils::ExposedHosts::HostConstraint
  def initialize(entries)
    unless entries.is_a?(Array) && entries.all?(GetaroundUtils::ExposedHosts::Entry)
      raise ArgumentError, "expected a list of entries, got #{entries.inspect}"
    end

    @private_entries, @public_entries = entries.partition(&:private?).each(&:freeze)
  end

  # A request without a Host header matches no private entry, but still matches a public entry on its forwarded host or
  # its SERVER_NAME.
  def matches?(request)
    private_request?(request) || public_request?(request)
  end

  private

  def private_request?(request)
    return false if @private_entries.empty?

    host = request.host_authority
    @private_entries.any? { |entry| entry.match?(host:) }
  end

  def public_request?(request)
    return false if @public_entries.empty?

    host = request.host
    @public_entries.any? { |entry| entry.match?(host:) }
  end
end
