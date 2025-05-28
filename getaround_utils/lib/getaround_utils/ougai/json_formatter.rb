# frozen_string_literal: true

require 'ougai'
require 'json'

module GetaroundUtils; end

module GetaroundUtils::Ougai; end

class GetaroundUtils::Ougai::JsonFormatter < Ougai::Formatters::Base
  def _call(severity, _time, progname, data)
    message = data.delete(:msg)
    data = { caption: message }.merge(data) \
      unless message == 'No message'

    payload = { severity:, progname: }.merge(data).compact
    "#{JSON.dump(payload)}\n"
  end
end
