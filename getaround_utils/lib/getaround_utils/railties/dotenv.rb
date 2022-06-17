# frozen_string_literal: true

require 'rails/railtie'

module GetaroundUtils; end

module GetaroundUtils::Railties; end

class GetaroundUtils::Railties::Dotenv < Rails::Railtie
  def load
    if ENV['DOTENVS'].present?
      overrides = ENV['DOTENVS'].split(',').map{ |n| [".env.#{n}.local", ".env.#{n}"] }.flatten
      warn('=' * 100)
      warn("⚠️  ENV is overriden with the following profiles: #{overrides}")
      warn('=' * 100)
      Dotenv.load(*overrides)
    end
    Dotenv::Railtie.load
    Dotenv.load('.env.all', '.env.all.local')
    nil
  end
end
