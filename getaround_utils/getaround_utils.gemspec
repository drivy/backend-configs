require_relative './lib/getaround_utils/version'

Gem::Specification.new do |gem|
  gem.name          = 'getaround_utils'
  gem.version       = GetaroundUtils::VERSION
  gem.summary       = 'Backend shared utility classes'
  gem.description   = 'Shared base utility classes for Getaround Backend Applications.'
  gem.authors       = ['Drivy', 'Laurent Humez']
  gem.email         = ['oss@drivy.com']
  gem.homepage      = 'https://github.com/drivy'
  gem.license       = 'MIT'

  gem.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec)/}) }
  end

  # Development dependencies
  gem.add_development_dependency 'bundler', '~> 2.0'
  gem.add_development_dependency 'getaround-rubocop', '~> 0.1.0', '>= 0.1.0'
  gem.add_development_dependency 'pry', '~> 0.12.2'
  gem.add_development_dependency 'rake', '~> 13.0'
  gem.add_development_dependency 'rspec', '~> 3.9', '>= 3.9.0'
  gem.add_development_dependency 'rspec-rails', '~> 4.0'
  gem.add_development_dependency 'rubocop', '~> 0.75', '>= 0.75.0'
  gem.add_development_dependency 'rubocop-rspec', '~> 1.36', '>= 0.36.0'
  gem.add_development_dependency 'webmock', '~> 3.7'

  # Functional (optional) dependencies
  gem.add_development_dependency 'lograge', '~> 0.11.2'
  gem.add_development_dependency 'ougai', '~> 1.8'
  gem.add_development_dependency 'rails', '~> 6.0'
  gem.add_development_dependency 'request_store_rails', '~> 2.0'
  gem.add_development_dependency 'sidekiq', '~> 6.0'
end
