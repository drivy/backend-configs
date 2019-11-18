# frozen_string_literal: true

GEM_NAMES = %w(
  getaround-rubocop
  getaround_utils
)

root = File.expand_path(__dir__)
build_path = "#{root}/build"

namespace :gem do
  # Tasks build:<gem>, build:all
  namespace :build do
    GEM_NAMES.each do |gem_name|
      desc "Build the #{gem_name} gem"
      task gem_name do
        sh "mkdir -p #{build_path}"
        sh "(cd #{root}/#{gem_name} && gem build #{gem_name})"
        sh "mv #{gem_name}/#{gem_name}-*.gem #{build_path}"
      end
    end

    desc "Build gems: #{GEM_NAMES}"
    task all: GEM_NAMES
  end

  # Tasks push:<gem>, push:all
  namespace :push do
    GEM_NAMES.each do |gem_name|
      desc "Push the #{gem_name} gem"
      task gem_name => "build:#{gem_name}" do
        sh "gem push #{build_path}/#{gem_name}-*.gem"
      end
    end

    desc "Build gems: #{GEM_NAMES}"
    task all: GEM_NAMES
  end

  # Tasks clean:<gem>, build:all
  namespace :clean do
    GEM_NAMES.each do |gem_name|
      desc "Cleanup the #{gem_name} gem artifacts"
      task gem_name do
        sh "rm -f #{build_path}/#{gem_name}-*.gem"
      end
    end

    desc "Build gems: #{GEM_NAMES}"
    task all: GEM_NAMES
  end
end
