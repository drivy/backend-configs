require 'json'
require 'faraday'
require 'getaround_utils/utils/async_queue'

class GetaroundUtils::Utils::CapturReporter < GetaroundUtils::Utils::AsyncQueue
  CAPTUR_URL = ENV['CAPTUR_URL']

  def perform(events)
    return unless CAPTUR_URL&.match('^https?://')

    Faraday.post(CAPTUR_URL) do |req|
      req.options[:open_timeout] = 1
      req.options[:timeout] = 1
      req.headers = { 'Content-Type': 'application/json' }
      req.body = JSON.generate(events: events, metas: metas)
    end
  end

  def metas
    {}
  end

  def push(uuid:, type:, anonymous_id:, timestamp: nil, attributes: {})
    super(
      uuid: uuid,
      type: type,
      timestamp: timestamp || Time.now.iso8601,
      anonymous_id: anonymous_id,
      attributes: attributes,
    )
  end
end
