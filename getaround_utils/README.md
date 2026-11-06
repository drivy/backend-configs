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

### GetaroundUtils::Railties::ExposedHosts

Declares the hosts the application is exposed on, public or private, and provides routing helpers that restrict routes to some of these hosts or generate their URLs on one of them.
```ruby
# config/application.rb
require 'getaround_utils/railties/exposed_hosts'
```
```yaml
# config/exposed_hosts.yml
production:
  default_url_options: { protocol: https }
  hosts:
    - { host: app.example.com, visibility: private }
    - { host: www.example.com, visibility: public }
    - { host: <%= ENV.fetch('LEGACY_HOST') %>, visibility: public, group: legacy }
```

- Each environment lists its hosts under `hosts`, and may set under `default_url_options` the URL options of the URLs generated on all of them. It has no other key.
- Each entry is validated: `host` (an exact host name, without port) and `visibility` (`public` or `private`) are required, any other key is kept as metadata, except `default_url_options`: those of that host, merged over those of the environment, e.g. `{ host: localhost, visibility: private, default_url_options: { port: 3001 } }`. No `default_url_options` can set `host`, which is always that of the entry.
- ERB and a `shared:` section work as in any `config_for` file. `shared:` is deep merged into the environment's section, so an environment that lists its own `hosts` replaces those of `shared:` rather than adding to them.
- The file is loaded as soon as the application class is defined, so the class body and the environment files can already read it. An invalid file fails the boot with a `GetaroundUtils::ExposedHosts::Configuration::Error`.

```ruby
exposed = Rails.configuration.exposed_hosts # a GetaroundUtils::ExposedHosts::Configuration
exposed.hosts                     # every declared host, once, in the file's order
exposed.entries                   # every entry, in the file's order, with its metadata
exposed.entries(:private)         # the entries of a visibility, :public or :private, in the file's order
exposed.entries(group: :api)      # the entries matching the metadata, whatever their visibility
exposed.entry(:public)            # the first of these entries
exposed.public_host               # the host of the first public entry
exposed.private_host              # the same, for the private entries
exposed.default_url_options       # => { protocol: 'https' } — the URL options of the environment

entry = exposed.entries.first     # a GetaroundUtils::ExposedHosts::Entry
entry.host                        # => 'app.example.com'
entry.visibility                  # => :private
entry.private?                    # => true
entry.public?                     # => false
entry.metadata                    # => {} — the other keys of the entry
entry.url_options                 # => { protocol: 'https', host: 'app.example.com' } — its default_url_options and its host
entry.to_h                        # => { host: 'app.example.com', visibility: :private } — with the metadata
entry.match?(group: :legacy)      # => false — whether the metadata holds these keys and values
entry.match?(host: authority)     # whether a Host header, e.g. 'APP.example.com:3000', designates this host

legacy = exposed.entries.last     # the entry of LEGACY_HOST
legacy.metadata                   # => { group: 'legacy' }
legacy.match?(group: :legacy)     # => true — a Symbol and a String with the same name are equal
```

`entries`, `entry`, `public_host` and `private_host` take an optional metadata filter, and then only consider the entries that match it: `entries(:private, group: :api)`, `private_host(group: :api)`. A Symbol and a String with the same name are equal, so `group: :api` matches the `group: api` of a YAML entry; other values compare strictly.

`Entry#match?` takes the same filter as keywords, and a `host`: `match?(host: authority, visibility: :private, group: :api)`. A criterion left out matches any entry, while a `nil` host, that of a request without a Host header, matches none.

They raise a `KeyError` that names the visibility and the metadata when no entry matches, e.g. `exposed_hosts: no private host matching {group: :api} is declared`: `entries` never returns an empty list.

The railtie does not touch `config.hosts`: each application adds the hosts it needs, for instance all of them:
```ruby
# config/application.rb
config.hosts += config.exposed_hosts.hosts
```
Once `config.hosts` is filled, a health check that does not send a declared host is blocked. Exclude it where the application sets its other environment options:
```ruby
health_check = ->(request) { request.path == '/up' || request.path.start_with?('/health/') }
config.host_authorization = { exclude: health_check }
config.ssl_options = { redirect: { exclude: health_check } } # only when redirecting to HTTPS without `config.assume_ssl`
```

The routes DSL gets three optional helpers:

- `host_constraint` restricts routes to the matching hosts: they answer nowhere else.
- `default_host` generates the URLs of routes with the `url_options` of the first matching host, without restricting where they answer.
- `private_routes` does both on the private hosts.

`host_constraint` and `default_host` take the same visibility and metadata filter as `entries`, and require at least one of them. `private_routes` only takes the metadata.

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # Only exist on the private hosts, and generate their URLs on the first of them, e.g. an admin
  private_routes do
    get '/admin', to: 'admin#index'
  end

  # Exist on every host, and generate their URLs on the first public host,
  # e.g. the webhooks of an application whose `default_url_options` point to its private host
  default_host(:public) do
    post '/webhooks/github', to: 'webhooks#github'
  end

  # Only exist on the hosts whose entry has `group: api`, public or private, and generate their URLs on the public one
  host_constraint(group: :api) do
    default_host(:public, group: :api) do
      post '/graphql', to: 'graphql#execute'
    end
  end
end
```
- **`host_constraint` and `private_routes` limit where a route answers, they do not authorize anyone**: the Host header is chosen by the client. Every private route must still authenticate its callers.
- `default_host` and `private_routes` set a param per key of the `url_options` of their entry, whatever the request says: `params[:host]`, and one per key of its `default_url_options`. Their controllers must not use parameters with these names.
- The URL options their entry does not set, e.g. a port, still come from the `default_url_options` of the routes, which can take those of an entry: `default_url_options(**Rails.configuration.exposed_hosts.entry(:public).url_options)`.
- `default_host` does not check that its host is one of those of `host_constraint`: give both the same filter, or the URLs point to a host where the routes do not answer. `private_routes` always does.
- Inside `host_constraint` or `private_routes`, a route that takes its own constraint object or lambda, e.g. `get '/admin', to: 'admin#index', constraints: LoggedIn.new`, drops the host constraint and answers on every host: Rails replaces the constraint of the block with that of the route. Nest it in a `constraints(LoggedIn.new) do` block instead. A hash of constraints, e.g. `constraints: { subdomain: 'www' }`, adds to the host constraint.
- Drawing any of them without a matching entry raises the `KeyError` of `entries`. Drawing `host_constraint` or `default_host` without visibility nor metadata raises an `ArgumentError`.

`host_constraint` matches the raw Host header against the hosts of the entries, in any case and with any port, and ignores `request.host`, which follows `X-Forwarded-Host`. Its `GetaroundUtils::ExposedHosts::HostConstraint` takes any Rack request, so the code that runs before the router can use it too:
```ruby
PRIVATE_API_HOSTS = GetaroundUtils::ExposedHosts::HostConstraint.new(Rails.configuration.exposed_hosts.entries(:private, group: :api))
PRIVATE_API_HOSTS.matches?(request) # whether the request targets a private host of the api group
```
It only takes a non-empty list of entries, and raises an `ArgumentError` for anything else.

The ERB of `config/exposed_hosts.yml` only sees the `.env` files loaded before the application class: load them at the top of `config/application.rb`, e.g. with `GetaroundUtils::Railties::Dotenv.load`. The `before_configuration` hook of `dotenv-rails` is not enough when this railtie is required first, as its own hook then runs first.

For more details, read the specs of [the railtie](spec/getaround_utils/railties/exposed_hosts_spec.rb), [the configuration](spec/getaround_utils/exposed_hosts/configuration_spec.rb), [the entry](spec/getaround_utils/exposed_hosts/entry_spec.rb), [the host constraint](spec/getaround_utils/exposed_hosts/host_constraint_spec.rb) and [the routing helpers](spec/getaround_utils/exposed_hosts/routing_helpers_spec.rb). [The routes of the spec dummy application](spec/getaround_utils/exposed_hosts/dummy_routes_spec.rb) show where the URLs generated with each helper point, during a request and outside one.

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

This helper allows to manage configuration urls with username and password extracted in dedicated variables.

Uses `*_URL` variable and tries to compute `*_USERNAME` and `*_PASSWORD` variables inside the parsed url.

```dotenv
FOO_URL="redis://foo@localhost:666/10"
FOO_PASSWORD="added-pwd"
BAR_URL="whatever://bar:baz@localhost:666/42"
BAR_USERNAME="user666"
BAR_PASSWORD="new-pwd"
ENV_TEST_NUMBER=1
```
```ruby
GetaroundUtils::Utils::ConfigUrl
  .from_env('FOO')
  .tap { |uri| uri.path += ENV['ENV_TEST_NUMBER'] }
# => <URI::Generic redis://foo:added-pwd@localhost:666/101>
GetaroundUtils::Utils::ConfigUrl.from_env('BAR').to_s
# => "whatever://user666:new-pwd@localhost:666/42"
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

### GetaroundUtils::Utils::HealthCheckFile

Helper to easily create health check file used for Kubernetes Probes (Sidekiq, Captur, etc...)

*Example in `config/initializers/sidekiq.rb`*
```ruby
SIDEKIQ_HEALTH_FILE = GetaroundUtils::Utils::HealthCheckFile.new('sidekiq')

Sidekiq.configure_server do |config|
  config.on(:startup) { SIDEKIQ_HEALTH_FILE.create }
  config.on(:beat) { SIDEKIQ_HEALTH_FILE.refresh }
  config.on(:shutdown) { SIDEKIQ_HEALTH_FILE.delete }
end
```

`refresh` only updates the modification time of an existing file. Sidekiq fires `:beat` every 10 seconds after a
successful Redis round trip, so a liveness probe can check the file age to detect a frozen process or a lost Redis
connection, e.g. `find tmp/sidekiq/health_check_file -mmin -1 | grep -q .`

For more details, [read the spec](spec/getaround_utils/utils/health_check_file_spec.rb)
