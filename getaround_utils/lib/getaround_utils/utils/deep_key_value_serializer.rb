module GetaroundUtils; end
module GetaroundUtils::Utils; end

class GetaroundUtils::Utils::DeepKeyValueSerializer
  def initialize(max_depth: 5, max_length: 512)
    @max_depth = max_depth
    @max_length = max_length
  end

  def serialize(data)
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
    if path.length > @max_depth
      result[path.join(".")] = '"..."'
      return result
    end
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
      value = if value =~ /^".*"$/
        value.length >= @max_length ? %{#{value[0...@max_length]} ..."} : value
      else
        value.length >= @max_length ? %{#{value[0...@max_length]} ...}.inspect : value.inspect
      end
      result[path.join(".")] = value
    else
      flattify(value.to_s, result, path)
    end
    result
  end
end
