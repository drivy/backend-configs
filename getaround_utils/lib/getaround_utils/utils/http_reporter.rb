class GetaroundUtils::Utils::HttpReporter
  include GetaroundUtils::Mixins::Loggable

  def initialize(_)
    loggable_log(:warn, 'use of deprecated class')
  end

  def report(_)
    loggable_log(:warn, 'use of deprecated class')
  end
end
