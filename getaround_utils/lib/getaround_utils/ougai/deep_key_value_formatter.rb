# frozen_string_literal: true

require 'ougai'
require 'getaround_utils/utils/deep_key_value'

module GetaroundUtils; end

module GetaroundUtils::Ougai; end

class GetaroundUtils::Ougai::DeepKeyValueFormatter < Ougai::Formatters::Base
  def _call(severity, _time, progname, data)
    message = data.delete(:msg)
    data[:message] = message if message != 'No message'

    payload = { severity: severity, progname: progname }.merge(data).compact
    "#{GetaroundUtils::Utils::DeepKeyValue.serialize(payload)}\n"
  end
end
