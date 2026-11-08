# frozen_string_literal: true

module GetaroundUtils; end

module GetaroundUtils::ExposedHosts; end

class GetaroundUtils::ExposedHosts::Entry
  attr_reader :host, :visibility, :metadata, :url_options

  class Error < StandardError; end

  VISIBILITIES = %i[public private].freeze
  REQUIRED_KEYS = %i[host visibility].freeze
  NO_ARG = Object.new.freeze
  private_constant :NO_ARG

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

  def match_host?(authority)
    @host_pattern.match?(authority)
  end

  def match_metadata?(**metadata)
    metadata.all? do |key, value|
      self.metadata.key?(key) && comparable(self.metadata[key]) == comparable(value)
    end
  end

  def comparable(value)
    value.is_a?(Symbol) ? value.name : value
  end
end
