$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'rspec'
require 'webmock/rspec'
require 'pp'
require 'active_support'
require 'active_support/core_ext'

require 'sports_south'

# Require all files from the /spec/support dir
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  config.include FixtureHelper
  config.include SampleResponses
end
