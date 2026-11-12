# frozen_string_literal: true

module GetaroundUtils; end

module GetaroundUtils::ExposedHosts; end

# A host of config/exposed_hosts.yml: its visibility, the URL options of the URLs generated on it, and any other key of
# the entry as metadata.
class GetaroundUtils::ExposedHosts::Entry
  attr_reader :host, :visibility, :metadata, :url_options

  class Error < StandardError; end

  VISIBILITIES = %i[public private].freeze
  REQUIRED_KEYS = %i[host visibility].freeze
  NO_ARG = Object.new.freeze
  private_constant :NO_ARG

  # Builds an entry from a hash of config/exposed_hosts.yml: `host`, `visibility`, its own `default_url_options` merged
  # over the given ones, e.g. those of its environment, and any other key as metadata.
  def self.build(raw_entry, default_url_options: {})
    unless valid_default_url_options?(default_url_options)
      raise ArgumentError, "default_url_options must be a hash without host, got #{default_url_options.inspect}"
    end
    raise Error, "expected a hash, got #{raw_entry.inspect}" unless raw_entry.is_a?(Hash)

    missing_keys = REQUIRED_KEYS - raw_entry.keys
    raise Error, "missing required keys: #{missing_keys.join(', ')}" if missing_keys.any?

    if raw_entry.key?(:default_url_options) && !valid_default_url_options?(raw_entry[:default_url_options])
      raise Error, "default_url_options must be a hash without host, got #{raw_entry[:default_url_options].inspect}"
    end

    new(
      **raw_entry.except(:default_url_options),
      default_url_options: default_url_options.merge(raw_entry.fetch(:default_url_options, {}))
    )
  end

  def self.valid_visibility?(visibility)
    (visibility.is_a?(String) || visibility.is_a?(Symbol)) && VISIBILITIES.include?(visibility.to_sym)
  end

  # The host of the URLs is always that of the entry: default URL options cannot set it.
  def self.valid_default_url_options?(default_url_options)
    default_url_options.is_a?(Hash) && !default_url_options.key?(:host)
  end

  def initialize(host:, visibility:, default_url_options: {}, **metadata)
    raise Error, "host must be a non-empty string, got #{host.inspect}" unless host.is_a?(String) && !host.empty?
    raise Error, "host must not start with a dot, got #{host.inspect}" if host.start_with?('.')
    raise Error, "host must not include a port, got #{host.inspect}" if host.include?(':')
    raise Error, "visibility must be public or private, got #{visibility.inspect}" unless self.class.valid_visibility?(visibility)
    unless self.class.valid_default_url_options?(default_url_options)
      raise Error, "default_url_options must be a hash without host, got #{default_url_options.inspect}"
    end

    @host = host.freeze
    @visibility = visibility.to_sym
    @metadata = metadata.freeze
    @url_options = default_url_options.merge(host:).freeze
    @host_pattern = /\A#{Regexp.escape(host)}(?::\d+)?\z/i
    freeze
  end

  # Whether the entry has the given host, visibility and metadata, e.g. `match?(visibility: :private, group: 'api')`.
  # A criterion left out matches any entry, while a nil host, that of a request without a Host header, matches none.
  def match?(host: NO_ARG, visibility: NO_ARG, **metadata)
    raise ArgumentError, "visibility must be public or private, got #{visibility.inspect}" unless NO_ARG.equal?(visibility) || self.class.valid_visibility?(visibility)

    return false unless NO_ARG.equal?(host) || match_host?(host)
    return false unless NO_ARG.equal?(visibility) || self.visibility == visibility.to_sym

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

  # Whether a Host header designates this host, in any case and with any port, e.g. `match_host?('WWW.example.com:3000')`.
  # It is the comparison HostAuthorization makes for a host without a leading dot, hence the rules on the host.
  def match_host?(authority)
    @host_pattern.match?(authority)
  end

  # Whether the metadata holds all the given keys with the given values, e.g. `match_metadata?(group: :api)`.
  # A Symbol and a String with the same name are equal: the values of a flow-style YAML entry are strings.
  def match_metadata?(**metadata)
    metadata.all? do |key, value|
      self.metadata.key?(key) && comparable(self.metadata[key]) == comparable(value)
    end
  end

  def comparable(value)
    value.is_a?(Symbol) ? value.name : value
  end
end
