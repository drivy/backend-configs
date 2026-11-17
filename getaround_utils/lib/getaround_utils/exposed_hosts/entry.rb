# frozen_string_literal: true

module GetaroundUtils; end

module GetaroundUtils::ExposedHosts; end

# A host of config/exposed_hosts.yml: its visibility, and any other key of the entry as metadata.
class GetaroundUtils::ExposedHosts::Entry
  attr_reader :host, :visibility, :metadata

  class Error < StandardError; end

  VISIBILITIES = %i[public private].freeze
  REQUIRED_KEYS = %i[host visibility].freeze
  NO_ARG = Object.new.freeze
  private_constant :NO_ARG

  # Builds an entry from a hash of config/exposed_hosts.yml: `host`, `visibility`, and any other key as metadata.
  def self.build(raw_entry)
    raise Error, "expected a hash, got #{raw_entry.inspect}" unless raw_entry.is_a?(Hash)

    missing_keys = REQUIRED_KEYS - raw_entry.keys
    raise Error, "missing required keys: #{missing_keys.join(', ')}" if missing_keys.any?

    new(**raw_entry)
  end

  def self.valid_visibility?(visibility)
    (visibility.is_a?(String) || visibility.is_a?(Symbol)) && VISIBILITIES.include?(visibility.to_sym)
  end

  def initialize(host:, visibility:, **metadata)
    raise Error, "visibility must be public or private, got #{visibility.inspect}" unless self.class.valid_visibility?(visibility)
    # The rules on the host keep `@host_pattern` identical to the pattern HostAuthorization builds for the same host.
    # HostAuthorization only builds such a pattern for a String, and an empty host would match an empty Host header.
    raise Error, "host must be a non-empty string, got #{host.inspect}" unless host.is_a?(String) && !host.empty?
    # HostAuthorization reads a leading dot as a wildcard for the subdomains.
    raise Error, "host must not start with a dot, got #{host.inspect}" if host.start_with?('.')
    # HostAuthorization allows a host declared with a port on that port only, while an entry matches any port.
    raise Error, "host must not include a port, got #{host.inspect}" if host.include?(':')

    @host = host.freeze
    @visibility = visibility.to_sym
    @metadata = metadata.freeze
    @host_pattern = /\A#{Regexp.escape(host)}(?::\d+)?\z/i
  end

  # Whether the entry has the given host, visibility and metadata, e.g. `match?(visibility: :private, group: 'api')`.
  # A criterion left out matches any entry, while a nil host, that of a request without a Host header, matches none,
  # and neither does a visibility that is not public or private.
  def match?(host: NO_ARG, visibility: NO_ARG, **metadata)
    return false unless visibility == NO_ARG || match_visibility?(visibility)
    return false unless host == NO_ARG || match_host?(host)

    match_metadata?(**metadata)
  end

  def public?
    visibility == :public
  end

  def private?
    visibility == :private
  end

  def to_h
    { host:, visibility:, **metadata }
  end

  private

  def match_visibility?(visibility)
    comparable(self.visibility) == comparable(visibility)
  end

  # Whether a Host header designates this host, in any case and with any port, e.g. `match_host?('WWW.example.com:3000')`.
  # It is the comparison HostAuthorization makes for a host without a leading dot nor a port, hence the rules on the
  # host in `initialize`.
  def match_host?(authority)
    @host_pattern.match?(authority)
  end

  # Whether the metadata holds all the given keys with the given values, e.g. `match_metadata?(group: :api)`.
  # A Symbol and a String with the same name are equal: YAML loads `group: api` as a String, and `group: :api`, which
  # only the block style accepts, as a Symbol.
  def match_metadata?(**metadata)
    metadata.all? do |key, value|
      self.metadata.key?(key) && comparable(self.metadata[key]) == comparable(value)
    end
  end

  def comparable(value)
    value.is_a?(Symbol) ? value.name : value
  end
end
