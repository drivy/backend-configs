# frozen_string_literal: true

Gem::Specification.new do |gem|
  gem.name = "getaround-rubocop"
  gem.version = '0.2.11'
  gem.summary = "Backend configuration files"
  gem.description = "Shared base configuration for Getaround Backend Applications."
  gem.authors = ["Drivy", "Laurent Humez"]
  gem.email = ["oss@drivy.com"]
  gem.homepage = "https://github.com/drivy"
  gem.license = "MIT"
  gem.required_ruby_version = '>= 3.3'

  gem.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec)/}) }
  end

  gem.add_runtime_dependency 'relaxed-rubocop', '~> 2.5'
  gem.add_runtime_dependency 'rubocop', '~> 1.0'
  gem.add_runtime_dependency 'rubocop-performance', '~> 1.0'
  gem.add_runtime_dependency 'rubocop-rails', '~> 2.0'
  gem.add_runtime_dependency 'rubocop-rspec', '~> 3.0'
end
