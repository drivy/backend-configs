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
  gem.required_ruby_version = '>= 3.3'

  gem.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec)/}) }
  end

  # Development dependencies
  gem.add_development_dependency 'getaround-rubocop', '= 0.2.11'
  gem.add_development_dependency 'irb', '~> 1.15'
  gem.add_development_dependency 'rake', '~> 13.2'
  gem.add_development_dependency 'rspec', '~> 3.13'
  gem.add_development_dependency 'rspec-rails', '~> 8.0'
  gem.add_development_dependency 'rubocop', '~> 1.81.6'
  gem.add_development_dependency 'webmock', '~> 3.25'

  # Functional (optional) dependencies
  gem.add_development_dependency 'dotenv', '~> 3.1.8'
  gem.add_development_dependency 'lograge', '~> 0.14.0'
  gem.add_development_dependency 'ougai', '~> 2.0'
  gem.add_development_dependency 'rack', '> 2.2'
  gem.add_development_dependency 'rails', '~> 7.0'
  gem.add_development_dependency 'sidekiq', '> 7.0'
end
