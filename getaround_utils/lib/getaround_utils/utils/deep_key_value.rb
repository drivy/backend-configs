module GetaroundUtils; end
module GetaroundUtils::Utils; end

module GetaroundUtils::Utils::DeepKeyValue
  def self.escape(value, max_length = 512)
    value = value[1...-1] if value =~ /^".*"$/
    value = "#{value[0...max_length]} ..." if value.length >= max_length
    value.inspect
  end

  def self.serialize(data)
    case data
    when Array
      flattify(data).map { |key, value| "#{key}=#{serialize(value)}" }.join(' ')
    when Hash
      flattify(data).map { |key, value| "#{key}=#{serialize(value)}" }.join(' ')
    when Numeric
      data.to_s
    when String
      escape(data)
    else
      escape(data.to_s)
    end
  end

  # https://stackoverflow.com/questions/48836464/how-to-flatten-a-hash-making-each-key-a-unique-value
  def self.flattify(value, result = {}, path = [], max_depth = 5)
    if path.length > max_depth
      result[path.join(".")] = '...'
      return result
    end
    case value
    when Array
      value.each.with_index(0) do |v, i|
        flattify(v, result, path + [i], max_depth)
      end
    when Hash
      value.each do |k, v|
        flattify(v, result, path + [k], max_depth)
      end
    when Numeric
      result[path.join(".")] = value
    when String
      result[path.join(".")] = value
    else
      flattify(value.to_s, result, path, max_depth)
    end
    result
  end
end
