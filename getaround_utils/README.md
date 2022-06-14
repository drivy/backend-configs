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

- Enables lograge (http logs) with favored default.
```ruby
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

- Offers an abstraction to log messages with a configurable `alert_threshold` attribute

```ruby
class MyClass
  include GetaroundUtils::Mixins::Loggable

  def action
    monitorable_log(:my_event_to_be_monitored, dynamic: 'value')
  end
end

MyClass.new.action # :info message="monitorable_log__my_event_to_be_monitored" origin="MyClass" dynamic="value", threshold=10
```
The threshold is configured in the relevant Rails configuration (eg `config/environments/production.rb`)
```ruby
# ...
  config.monitorable_log_thresholds = {
    my_event_to_be_monitored: 10
  }
# ...
```
You may set / override the configured thresholds with an environment variable of the event name prefixed with `MONITORABLE_LOG__`, for instance `MONITORABLE_LOG__MY_EVENT_TO_BE_MONITORED`.

For more details, [read the spec](spec/getaround_utils/mixins/loggable_spec.rb#L171)

## Misc

### GetaroundUtils::LogFormatters::DeepKeyValue

This log formatter will serialize an object of any depth into a key-value string.
It supports basic scalars (ie: `Hash`,`Array`,`Numeric`,`String`) and will call "#inspect" for any other type.

For more details, [read the spec](spec/getaround_utils/log_formatters/deep_key_value_spec.rb)


