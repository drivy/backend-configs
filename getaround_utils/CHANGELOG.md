## [Unreleased]

### Added

- `GetaroundUtils::Utils::ConfigUrl` ([#432](https://github.com/drivy/backend-configs/pull/432))
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
