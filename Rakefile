# frozen_string_literal: true

GEM_NAMES = %w(
  getaround-rubocop
  getaround-utils
)

root = File.expand_path(__dir__)
build_path = "#{root}/build"

namespace :gem do
  namespace :build do
    GEM_NAMES.each do |gem_name|
      desc "Build the #{gem_name} gem"
      task gem_name do
        version = File.read("#{root}/#{gem_name}/VERSION")
        sh "mkdir -p #{build_path}"
        sh "(cd #{root}/#{gem_name} && gem build #{gem_name})"
        sh "mv #{gem_name}/#{gem_name}-#{version}.gem #{build_path}"
      end
    end

    desc "Build gems: #{GEM_NAMES}"
    task all: GEM_NAMES
  end

  namespace :push do
    GEM_NAMES.each do |gem_name|
      desc "Push the #{gem_name} gem"
      task gem_name => "build:#{gem_name}" do
        version = File.read("#{root}/#{gem_name}/VERSION")
        sh "gem push #{build_path}/#{gem_name}-#{version}.gem"
      end
    end

    desc "Build gems: #{GEM_NAMES}"
    task all: GEM_NAMES
  end
end
