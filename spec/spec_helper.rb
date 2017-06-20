$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'rspec'
require 'webmock/rspec'
require 'pp'

require 'sports_south'

# Require all files from the /spec/support dir
Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.include SampleResponses
end
