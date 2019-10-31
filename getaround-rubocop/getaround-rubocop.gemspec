Gem::Specification.new do |gem|
  gem.name          = "getaround-rubocop"
  gem.version       = File.read('./VERSION')
  gem.summary       = "Backend configuration files"
  gem.description   = "Shared base configuration for Getaround Backend Applications."
  gem.authors       = ["Drivy", "Laurent Humez"]
  gem.email         = ["oss@drivy.com"]
  gem.homepage      = "https://github.com/drivy"
  gem.license       = "MIT"

  gem.files         = Dir["{**/}{.*,*}"].select{ |path| File.file?(path) && path !~ /^(?:tmp)/ }

  gem.add_runtime_dependency "relaxed-rubocop", '~> 2.4', '>= 2.4.0'
  gem.add_runtime_dependency "rubocop", '~> 0.75', '>= 0.75.0'
end
