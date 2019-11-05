Gem::Specification.new do |gem|
  gem.name          = "getaround-rubocop"
  gem.version       = '0.1.0'
  gem.summary       = "Backend configuration files"
  gem.description   = "Shared base configuration for Getaround Backend Applications."
  gem.authors       = ["Drivy", "Laurent Humez"]
  gem.email         = ["oss@drivy.com"]
  gem.homepage      = "https://github.com/drivy"
  gem.license       = "MIT"

  gem.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec)/}) }
  end

  gem.add_runtime_dependency "relaxed-rubocop", '~> 2.4', '>= 2.4.0'
  gem.add_runtime_dependency "rubocop", '~> 0.75', '>= 0.75.0'
  gem.add_development_dependency 'rubocop-rspec', '~> 1.36', '>= 0.36.0'
end
