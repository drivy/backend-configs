# frozen_string_literal: true

module GetaroundUtils; end

module GetaroundUtils::ExposedHosts; end

# Raised when no entry of config/exposed_hosts.yml matches the criteria, e.g.
# `UndeclaredHost.new(exposure: :internal, group: 'api')`. Its message names the exposure and the metadata.
class GetaroundUtils::ExposedHosts::UndeclaredHost < StandardError
  def initialize(**criteria)
    exposure = criteria.delete(:exposure)
    exposed = " #{exposure}" unless exposure.nil?
    filter = " matching #{criteria.inspect}" if criteria.any?
    super("no#{exposed} host#{filter} is declared")
  end
end
