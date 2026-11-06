# frozen_string_literal: true

require 'rails'
require 'action_controller/railtie'
require 'getaround_utils/railties/exposed_hosts'
require 'getaround_utils/railties/lograge'
require 'getaround_utils/railties/ougai'

ENV['DUMMY_PRIVATE_HOST'] = 'private.example.com'

class DummyApplication < Rails::Application
  config.load_defaults 8.1
  config.eager_load = false
  config.log_level = :info
  config.monitorable_log_thresholds = {}
end
