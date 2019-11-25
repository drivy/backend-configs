module GetaroundUtils; end
module GetaroundUtils::Utils; end

module GetaroundUtils::Utils::DeepKeyValue
  def self.serialize(data)
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
  def self.flattify(value, result = {}, path = [], max_length = 512, max_depth = 5)
    if path.length > max_depth
      result[path.join(".")] = '"..."'
      return result
    end
    case value
    when Array
      value.each.with_index(0) do |v, i|
        flattify(v, result, path + [i], max_length, max_depth)
      end
    when Hash
      value.each do |k, v|
        flattify(v, result, path + [k], max_length, max_depth)
      end
    when Numeric
      result[path.join(".")] = value.to_s
    when String
      value = if value =~ /^".*"$/
        value.length >= max_length ? %{#{value[0...max_length]} ..."} : value
      else
        value.length >= max_length ? %{#{value[0...max_length]} ...}.inspect : value.inspect
      end
      result[path.join(".")] = value
    else
      flattify(value.to_s, result, path, max_length, max_depth)
    end
    result
  end
end
