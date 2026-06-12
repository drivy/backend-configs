# frozen_string_literal: true

require 'fileutils'
require 'pathname'

module GetaroundUtils; end

module GetaroundUtils::Utils; end

class GetaroundUtils::Utils::HealthCheckFile
  FILE_NAME = 'health_check_file'

  attr_reader :path

  def initialize(name)
    raise ArgumentError, "Expected name as String, got: #{name.inspect}" if !name.is_a?(String) || name.empty?

    @base_path = root_path.join('tmp', name)
    @path = @base_path.join(FILE_NAME)
  end

  def create
    FileUtils.mkdir_p(@base_path)
    FileUtils.touch(@path)
  end

  def delete
    FileUtils.rm_f(@path)
  end

  def exists?
    File.exist?(@path)
  end

  private

  def root_path
    defined?(::Rails) ? Rails.root : Pathname.new('/')
  end
end
