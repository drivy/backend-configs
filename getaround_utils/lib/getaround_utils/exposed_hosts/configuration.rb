# frozen_string_literal: true

require 'getaround_utils/exposed_hosts/entry'
require 'getaround_utils/exposed_hosts/undeclared_host'

module GetaroundUtils; end

module GetaroundUtils::ExposedHosts; end

# The section of an environment in config/exposed_hosts.yml: its `hosts`, validated and turned into entries. It has
# no other key.
class GetaroundUtils::ExposedHosts::Configuration
  attr_reader :hosts

  class Error < StandardError; end

  NO_ARG = Object.new.freeze
  private_constant :NO_ARG

  def initialize(section)
    raise Error, "the environment section must be a hash, got #{section.inspect}" unless section.is_a?(Hash)

    unknown_keys = section.keys - [:hosts]
    raise Error, "unknown keys: #{unknown_keys.join(', ')}" if unknown_keys.any?
    raise Error, 'missing key: hosts' unless section.key?(:hosts)

    @entries = build_entries(section[:hosts]).freeze
    @hosts = @entries.map(&:host).uniq.freeze
  end

  # The entries that have the visibility and match the other criteria, in the file's order, e.g.
  # `entries(:private, group: 'api')`. Without visibility, whatever their visibility, and without any criterion, every
  # entry. Raises an UndeclaredHost when there is none.
  # The keywords are the criteria of `Entry#match?`: metadata, but also a `host`, e.g. `entries(host: authority)`, or
  # the visibility, e.g. `entries(visibility: :private)`. The visibility is public or private, as a Symbol or a String,
  # given as an argument or as a keyword but not both: anything else raises an ArgumentError.
  def entries(visibility = NO_ARG, **)
    criteria = criteria_for(visibility, **)
    @entries.select { |entry| entry.match?(**criteria) }.freeze.tap do |entries|
      undeclared_host!(**criteria) if entries.empty?
    end
  end

  # The first entry that has the visibility and matches the other criteria, e.g. `entry(:public, group: 'api')`. It
  # takes the arguments of `entries`, and raises the same errors, but requires the visibility as an argument.
  def entry(visibility, **)
    criteria = criteria_for(visibility, **)
    @entries.find { |entry| entry.match?(**criteria) } || undeclared_host!(**criteria)
  end

  private

  def build_entries(raw_entries)
    raise Error, "hosts must be a list, got #{raw_entries.inspect}" unless raw_entries.is_a?(Array)

    raw_entries.each.with_index(1).map do |raw_entry, position|
      GetaroundUtils::ExposedHosts::Entry.build(raw_entry).freeze
    rescue GetaroundUtils::ExposedHosts::Entry::Error => e
      raise Error, "hosts entry ##{position}: #{e.message}"
    end
  end

  def criteria_for(visibility, **kwargs)
    if visibility != NO_ARG && kwargs.key?(:visibility)
      raise ArgumentError, "visibility must be given once, got #{visibility.inspect} and visibility: #{kwargs[:visibility].inspect}"
    end

    criteria = visibility == NO_ARG ? kwargs : kwargs.merge(visibility:)
    if criteria.key?(:visibility) && !GetaroundUtils::ExposedHosts::Entry.valid_visibility?(criteria[:visibility])
      raise ArgumentError, "visibility must be public or private, got #{criteria[:visibility].inspect}"
    end

    criteria
  end

  def undeclared_host!(**)
    raise GetaroundUtils::ExposedHosts::UndeclaredHost.new(**)
  end
end
