# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'

require 'sidekiq'
require 'rails'
require 'action_controller/railtie'
require 'getaround_utils/railties/lograge'
require 'getaround_utils/railties/ougai'

class DummyApplication < Rails::Application
  config.load_defaults 6.0
  config.eager_load = false
  config.log_level = :info
  config.monitorable_log_thresholds = {}
end

Rails.application.initialize!

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
  config.before do
  end
end
