require 'tempfile'

require 'webmock/rspec'

RSpec.configure do |config|
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'getaround_utils'
