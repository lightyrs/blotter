require_relative '../lib/blotter'
require_relative 'rails/facebook_page'

RSpec.configure do |config|
  config.mock_with :rr
  # or if that doesn't work due to a version incompatibility
  # config.mock_with RR::Adapters::Rspec
end
