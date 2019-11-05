# getaround_utils

Backend shared utility classes

## Railties

### `GetaroundUtils::Railties::Lograge`

To enable lograge (http logs) with the default, just add to your `config/application.rb`
```
require 'getaround_utils/railties/lograge'
```

For more details, [read the spec](getaround_utils/spec/getaround_utils/railties/lograge_spec.rb)

## Misc

### `GetaroundUtils::LogFormatters::DeepKeyValue`

This log formatter will serialize an object of any depth into a key-value string.
It supports basic scalars (ie: `Hash`,`Array`,`Numeric`,`String`) and will call "#inspect" for any other type.

For more details, [read the spec](getaround_utils/spec/getaround_utils/log_formatters/deep_key_value_spec.rb)


