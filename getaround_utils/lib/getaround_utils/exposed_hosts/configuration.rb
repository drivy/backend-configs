# frozen_string_literal: true

require 'getaround_utils/exposed_hosts/entry'

module GetaroundUtils; end

module GetaroundUtils::ExposedHosts; end

# The section of an environment in config/exposed_hosts.yml: its `hosts`, validated and turned into entries, and its
# optional `default_url_options`, which every entry merges its own over. It has no other key.
class GetaroundUtils::ExposedHosts::Configuration
  class Error < StandardError; end

  attr_reader :hosts, :default_url_options

  def initialize(section)
    raise Error, "the environment section must be a hash, got #{section.inspect}" unless section.is_a?(Hash)

    unknown_keys = section.keys - [:hosts, :default_url_options]
    raise Error, "unknown keys: #{unknown_keys.join(', ')}" if unknown_keys.any?
    raise Error, 'missing key: hosts' unless section.key?(:hosts)
    if section.key?(:default_url_options) && !GetaroundUtils::ExposedHosts::Entry.valid_default_url_options?(section[:default_url_options])
      raise Error, "default_url_options: expected a hash without host, got #{section[:default_url_options].inspect}"
    end

    @default_url_options = section.fetch(:default_url_options, {}).freeze
    @entries = build_entries(section[:hosts]).freeze
    @hosts = @entries.map(&:host).uniq.freeze
  end

  # The entries of the visibility matching the metadata, in the file's order, e.g. `entries(:private, group: 'api')`.
  # Without visibility, whatever their visibility; without metadata, every entry of the visibility.
  # Raises a KeyError when there is none.
  def entries(visibility = nil, **metadata)
    unless visibility.nil? || GetaroundUtils::ExposedHosts::Entry.valid_visibility?(visibility)
      raise ArgumentError, "visibility must be public or private, got #{visibility.inspect}"
    end

    criteria = visibility.nil? ? metadata : { visibility:, **metadata }
    @entries
      .select { |entry| entry.match?(**criteria) }
      .tap { |entries| missing_host!(visibility, **metadata) if entries.empty? }
      .freeze
  end

  # The first of these entries, e.g. `entry(:public, group: 'api')`. Raises a KeyError when there is none.
  def entry(...)
    entries(...).first
  end

  # The host of the first public entry matching the metadata, e.g. `public_host(group: 'api')`.
  def public_host(**metadata)
    entry(:public, **metadata).host
  end

  # The host of the first private entry matching the metadata.
  def private_host(**metadata)
    entry(:private, **metadata).host
  end

  private

  def build_entries(raw_entries)
    raise Error, "hosts must be a list, got #{raw_entries.inspect}" unless raw_entries.is_a?(Array)

    raw_entries.each.with_index(1).map do |raw_entry, position|
      GetaroundUtils::ExposedHosts::Entry.build(raw_entry, default_url_options:)
    rescue GetaroundUtils::ExposedHosts::Entry::Error => e
      raise Error, "hosts entry ##{position}: #{e.message}"
    end
  end

  def missing_host!(visibility, **metadata)
    visible = " #{visibility}" unless visibility.nil?
    filter = " matching #{metadata.inspect}" if metadata.any?
    raise KeyError, "exposed_hosts: no#{visible} host#{filter} is declared"
  end
end
