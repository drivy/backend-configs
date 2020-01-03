require 'json'
require 'faraday'

class GetaroundUtils::Utils::HttpReporter
  class AsyncQueue < GetaroundUtils::Utils::AsyncQueue
    def self.perform(url:, params: {}, headers: {}, body: nil)
      Faraday.post(url) do |req|
        req.params = params
        req.headers = headers
        req.body = body
      end
    end
  end

  def initialize(url:)
    @url = url
  end

  def report(event)
    AsyncQueue.perform_async(
      url: @url,
      headers: { 'Content-Type' => 'application/json' },
      body: JSON.generate(event)
    )
  end
end
