module GetaroundUtils; end
module GetaroundUtils::LogFormatters; end

class GetaroundUtils::LogFormatters::DeepKeyValue
  def call(data)
    case data
    when Array
      flattify(data).map { |key, value| "#{key}=#{value}" }.join(' ')
    when Hash
      flattify(data).map { |key, value| "#{key}=#{value}" }.join(' ')
    when Numeric
      data.to_s
    when String
      data =~ /^".*"$/ ? data : data.inspect
    else
      data.to_s.inspect
    end
  end

  # https://stackoverflow.com/questions/48836464/how-to-flatten-a-hash-making-each-key-a-unique-value
  def flattify(value, result = {}, path = [])
    case value
    when Array
      value.each.with_index(0) do |v, i|
        flattify(v, result, path + [i])
      end
    when Hash
      value.each do |k, v|
        flattify(v, result, path + [k])
      end
    when Numeric
      result[path.join(".")] = value.to_s
    when String
      result[path.join(".")] = value =~ /^".*"$/ ? value : value.inspect
    else
      result[path.join(".")] = value.to_s.inspect
    end
    result
  end
end
