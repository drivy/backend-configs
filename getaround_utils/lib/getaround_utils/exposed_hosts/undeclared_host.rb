# frozen_string_literal: true

module GetaroundUtils; end

module GetaroundUtils::ExposedHosts; end

# Raised when no entry of config/exposed_hosts.yml matches the criteria, e.g.
# `UndeclaredHost.new(visibility: :private, group: 'api')`. Its message names the visibility and the metadata.
class GetaroundUtils::ExposedHosts::UndeclaredHost < StandardError
  def initialize(**criteria)
    visibility = criteria.delete(:visibility)
    visible = " #{visibility}" unless visibility.nil?
    filter = " matching #{criteria.inspect}" if criteria.any?
    super("no#{visible} host#{filter} is declared")
  end
end
