# frozen_string_literal: true

require 'json'
require 'rack'

module GetaroundUtils; end

module GetaroundUtils::Engines; end

module GetaroundUtils::Engines::Health
  RELEASE_VERSION_PATH = '/health/release_version'
  COMMIT_SHA1_PATH = '/health/commit_sha1'
  MIGRATION_STATUS_PATH = '/health/migration_status'
  UNDEFINED = 'N/A'

  def self.release_version
    ENV['HEROKU_RELEASE_VERSION'] || ENV['PORTER_STACK_REVISION'] || ENV['PORTER_POD_REVISION']
  end

  def self.commit_sha1
    ENV['HEROKU_SLUG_COMMIT'] || ENV['COMMIT_SHA1']
  end

  def self.needs_migration?
    return false unless defined?(ActiveRecord)

    ActiveRecord::Base.connection.migration_context.needs_migration?
  end

  def self.engine
    Rack::Builder.new do
      map RELEASE_VERSION_PATH do
        use Rack::Head

        run(lambda do |env|
          req = Rack::Request.new(env)
          return [405, { 'Content-Type' => 'text/plain' }, []] unless req.get?

          content = GetaroundUtils::Engines::Health.release_version || UNDEFINED
          [200, { 'Content-Type' => 'text/plain' }, [content]]
        end)
      end

      map COMMIT_SHA1_PATH do
        use Rack::Head

        run(lambda do |env|
          req = Rack::Request.new(env)
          return [405, { 'Content-Type' => 'text/plain' }, []] unless req.get?

          content = GetaroundUtils::Engines::Health.commit_sha1 || UNDEFINED
          [200, { 'Content-Type' => 'text/plain' }, [content]]
        end)
      end

      map MIGRATION_STATUS_PATH do
        use Rack::Head

        run(lambda do |env|
          req = Rack::Request.new(env)
          return [405, { 'Content-Type' => 'application/json' }, []] unless req.get?

          content = { needs_migration: GetaroundUtils::Engines::Health.needs_migration? }
          [200, { 'Content-Type' => 'application/json' }, [JSON.generate(content)]]
        end)
      end
    end
  end
end
