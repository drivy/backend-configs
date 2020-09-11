# frozen_string_literal: true

require 'json'

module GetaroundUtils; end
module GetaroundUtils::Ougai; end

class GetaroundUtils::Ougai::JsonFormatter < Ougai::Formatters::Base
  def _call(severity, _time, progname, data)
    data.delete(:msg) if data[:msg] == 'No message'
    data = data.except(:msg).merge(message: data[:msg])

    payload = { severity: severity, progname: progname }.merge(data).compact!
    JSON.dump(payload) + "\n"
  end
end
