# frozen_string_literal: true

require_relative './lib/getaround_utils/version'

Gem::Specification.new do |gem|
  gem.name = 'getaround_utils'
  gem.version = GetaroundUtils::VERSION
  gem.summary = 'Backend shared utility classes'
  gem.description = 'Shared base utility classes for Getaround Backend Applications.'
  gem.authors = ['Drivy', 'Laurent Humez']
  gem.email = ['oss@drivy.com']
  gem.homepage = 'https://github.com/drivy'
  gem.license = 'MIT'
  gem.required_ruby_version = '>= 2.7'

  gem.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec)/}) }
  end

  # Development dependencies
  gem.add_development_dependency 'bundler', '~> 2.0'
  gem.add_development_dependency 'getaround-rubocop', '= 0.2.7'
  gem.add_development_dependency 'pry', '~> 0.14.0'
  gem.add_development_dependency 'rake', '~> 13.0'
  gem.add_development_dependency 'rspec', '~> 3.9', '>= 3.9.0'
  gem.add_development_dependency 'rspec-rails', '~> 5.0'
  gem.add_development_dependency 'rubocop', '= 1.25.1'
  gem.add_development_dependency 'webmock', '~> 3.7'

  # Functional (optional) dependencies
  gem.add_development_dependency 'lograge', '~> 0.12.0'
  gem.add_development_dependency 'ougai', '~> 2.0'
  gem.add_development_dependency 'rails', '~> 6.0'
  gem.add_development_dependency 'request_store_rails', '~> 2.0'
  gem.add_development_dependency 'sidekiq', '~> 6.0'
end
