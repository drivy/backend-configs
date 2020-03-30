# frozen_string_literal: true

Gem::Specification.new do |gem|
  gem.name          = "getaround-rubocop"
  gem.version       = '0.1.6'
  gem.summary       = "Backend configuration files"
  gem.description   = "Shared base configuration for Getaround Backend Applications."
  gem.authors       = ["Drivy", "Laurent Humez"]
  gem.email         = ["oss@drivy.com"]
  gem.homepage      = "https://github.com/drivy"
  gem.license       = "MIT"

  gem.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec)/}) }
  end

  gem.add_runtime_dependency "relaxed-rubocop", '= 2.5'
  gem.add_runtime_dependency "rubocop", '=  0.80.1'
  gem.add_development_dependency 'rubocop-rspec', '= 1.38'
end
