# getaround_utils

Backend shared utility classes

## Railties

### GetaroundUtils::Railties::Dotenv

Enable currated .env files loading
```
# config/application.rb
require 'getaround_utils/railties/dotenv'

GetaroundUtils::Railties::Dotenv.load
```

Additional files can be loaded with the highed precedence via the `DOTENVS` variable, ie:
```
DOTENVS=custom1,custom2 rails c
# Will `load` .env files in the following order:
# - `.env.custom1.local`
# - `.env.custom1`
# - `.env.custom2.local`
# - `.env.custom2`
# - `.env.<RAILS_ENV>.local`
# - `.env.<RAILS_ENV>`
# - `.env.all.local`
# - `.env.all`
# - `.env.local`
```

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

## Engines

### GetaroundUtils::Engine::Health

- Exposes the currently deployed release version:
  - `GetaroundUtils::Engine::Health.release_version`
- Exposes the currently deployed commit SHA1:
  - `GetaroundUtils::Engine::Health.commit_sha1`
- Provides a `Rack` application to expose "health" endpoints (used by Shipit)
  - `GET /release_version`
  - `GET /commit_sha1`
  - `GET /migration_status`

The engine can be mounted in a Rails application:
```ruby
# config/routes.rb
require 'getaround_utils/engines/health'

Rails.application.routes.draw do
  mount GetaroundUtils::Engines::Health.engine, at: '/health'
  # ...
end
```

Or in a simple `Rack` application:
```ruby
# config.ru
require 'getaround_utils/engines/health'

run Rack::Builder.new {
  map '/health' do
    run GetaroundUtils::Engines::Health.engine
  end
  # ...
}
```
*This will generates `/health/release_version`, `/health/commit_sha1` and `/health/migration_status` endpoints*

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

### GetaroundUtils::Utils::DeepKeyValue

This log formatter will serialize an object of any depth into a key-value string.
It supports basic scalars (ie: `Hash`,`Array`,`Numeric`,`String`) and will call "#inspect" for any other type.

For more details, [read the spec](spec/getaround_utils/utils/deep_key_value_spec.rb)

### GetaroundUtils::Utils::ConfigUrl

This helper allows to manage configuration urls with password extracted in a dedicated variable.

It uses `*_URL` variable and tries to compute `*_PASSWORD` inside the parsed url.

```ruby
# FOO_URL="redis://foo@localhost:666/10"
# FOO_PASSWORD="added-pwd"
# BAR_URL="whatever://bar:used-pwd@localhost:666/42"
# BAR_PASSWORD="not-used-pwd"
# ENV_TEST_NUMBER=1

GetaroundUtils::Utils::ConfigUrl
  .from_env('FOO')
  .tap { |uri| uri.path += ENV['ENV_TEST_NUMBER'] }
# => <URI::Generic redis://foo:added-pwd@localhost:666/101>
GetaroundUtils::Utils::ConfigUrl.from_env('BAR').to_s
# => "whatever://bar:used-pwd@localhost:666/42"
GetaroundUtils::Utils::ConfigUrl.from_env('UNKNOWN')
# => KeyError: key not found "UNKNOWN_URL"
GetaroundUtils::Utils::ConfigUrl.from_env('UNKNOWN', 'mysql://localhost/test')
# => <URI::Generic mysql://localhost/test>
GetaroundUtils::Utils::ConfigUrl.from_env('UNKNOWN') { GetaroundUtils::Utils::ConfigUrl.from_env('BAZ') }
# => KeyError: key not found "BAZ_URL"
```

For more details, [read the spec](spec/getaround_utils/utils/config_url_spec.rb)

### GetaroundUtils::Utils::HandleError

Allows to easily notify our error provider by providing context metadata as keyword arguments.

*If there is no error provider defined, a `debug` message will be logged using `GetaroundUtils::Mixins::Loggable`*

```ruby
module MyApp::Errors
  def self.handle(error, **)
    GetaroundUtils::Utils::HandleError.notify_of(error, **) do |event|
      event.grouping_hash = 'hello-world' # Bugsnag example
    end
  end
end

begin
  raise 'woopsie'
rescue StandardError => e
  MyApp::Errors.handle(e, foo: 'bar', baz: 42)
end
```

For more details, [read the spec](spec/getaround_utils/utils/handle_error_spec.rb)
