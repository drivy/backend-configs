require 'ougai'
require 'getaround_utils/utils/deep_key_value'

module GetaroundUtils; end
module GetaroundUtils::Ougai; end

class GetaroundUtils::Ougai::DeepKeyValuesFormatter < Ougai::Formatters::Base
  def _call(severity, time, progname, data)
    data.delete(:msg) if data[:msg] == 'No message'
    data = data.except(:msg).merge(message: data[:msg])

    payload = { severity: severity, progname: progname }.merge(data).compact!
    GetaroundUtils::Utils::DeepKeyValue.serialize(payload) + "\n"
  end
end
