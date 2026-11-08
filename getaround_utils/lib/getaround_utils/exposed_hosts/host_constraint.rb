# frozen_string_literal: true

require 'getaround_utils/exposed_hosts/entry'

module GetaroundUtils; end

module GetaroundUtils::ExposedHosts; end

class GetaroundUtils::ExposedHosts::HostConstraint
  def initialize(entries)
    raise ArgumentError, "expected a list of entries, got #{entries.inspect}" unless entries.is_a?(Array) && entries.all?(GetaroundUtils::ExposedHosts::Entry)
    raise ArgumentError, "expected at least one entry, got #{entries.inspect}" if entries.empty?

    @entries = entries.dup.freeze
  end

  def matches?(request)
    authority = request.host_authority
    @entries.any? { |entry| entry.match?(host: authority) }
  end
end
