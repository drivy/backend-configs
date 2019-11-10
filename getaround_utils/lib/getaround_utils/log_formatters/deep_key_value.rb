module GetaroundUtils; end
module GetaroundUtils::LogFormatters; end

module GetaroundUtils::LogFormatters
  class DeepKeyValue
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

    def call(severity, _datetime, appname, message)
      payload = { severity: severity, appname: appname }
      if message.is_a?(Hash)
        "#{serialize(payload.merge(message).compact)}\n"
      else
        "#{serialize(payload.merge(message: message.to_s).compact)}\n"
      end
    end

    module Lograge
      def call(data)
        data.compact! if data.is_a?(Hash)
        serialize(data)
      end
    end

    def self.for_lograge
      new.extend(Lograge)
    end

    module Sidekiq
      def call(severity, datetime, appname, message)
        payload = { tid: Thread.current['sidekiq_tid'] }
        payload.merge!(Thread.current[:sidekiq_context] || {})
        "#{super.chomp} #{serialize(sidekiq: payload.compact)}\n"
      end
    end

    def self.for_sidekiq
      new.extend(Sidekiq)
    end
  end
end
