# getaround_utils

Backend shared utility classes

## Railties

### `GetaroundUtils::Railties::Lograge`

Enables lograge (http logs) with favored default.
```
# config/application.rb
require 'getaround_utils/railties/lograge'
```

For more details, [read the spec](spec/getaround_utils/railties/lograge_spec.rb)

### `GetaroundUtils::Railties::KeyValueLogTags`

Enables parse-able key-value tags in ActiveRecord::TaggedLogger
```
# config/application.rb
require 'getaround_utils/railties/key_value_log_tags'
```

For more details, [read the spec](spec/getaround_utils/railties/key_value_log_tags.rb)

## Misc

### `GetaroundUtils::LogFormatters::DeepKeyValue`

This log formatter will serialize an object of any depth into a key-value string.
It supports basic scalars (ie: `Hash`,`Array`,`Numeric`,`String`) and will call "#inspect" for any other type.

For more details, [read the spec](spec/getaround_utils/log_formatters/deep_key_value_spec.rb)


