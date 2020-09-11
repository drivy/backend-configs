# getaround_utils

Backend shared utility classes

## Railties

### GetaroundUtils::Railties::Lograge

Enables lograge (http logs) with favored default.
```
# config/application.rb
require 'getaround_utils/railties/lograge'
```

For more details, [read the spec](spec/getaround_utils/railties/lograge_spec.rb)

### GetaroundUtils::Railties::Ougai

Enables structured log with Ougai.
```
# config/application.rb
require 'getaround_utils/railties/ougai'
```

For more details, [read the spec](spec/getaround_utils/railties/ougai_spec.rb)

## Mixins

### GetaroundUtils::Mixins::Loggable

Enables lograge (http logs) with favored default.
```
class MyClass
  include GetaroundUtils::Mixins::Loggable

  def append_infos_to_loggable(payload)
    payload[:static] = 'value'
  end

  def action
    loggable_log(:info, 'hello', dynamic: 'value')
  end
end

MyClass.new.action # :info message="hello" origin="MyClass" static="value" dynamic="value"

```

For more details, [read the spec](spec/getaround_utils/mixins/loggable_spec.rb)

## Misc

### GetaroundUtils::LogFormatters::DeepKeyValue

This log formatter will serialize an object of any depth into a key-value string.
It supports basic scalars (ie: `Hash`,`Array`,`Numeric`,`String`) and will call "#inspect" for any other type.

For more details, [read the spec](spec/getaround_utils/log_formatters/deep_key_value_spec.rb)


