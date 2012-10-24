require_relative 'rails/facebook_page' # mock application

require 'ostruct'
require 'simplecov'

SimpleCov.start

require_relative '../lib/blotter'

RSpec.configure do |config|
  config.mock_with :rr
  # or if that doesn't work due to a version incompatibility
  # config.mock_with RR::Adapters::Rspec
end
