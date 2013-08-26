require_relative 'rails/facebook_page' # mock application

require 'ostruct'
require 'timecop'
require 'active_support/core_ext'
require 'action_dispatch'
require 'simplecov'

SimpleCov.start

require_relative '../lib/blotter'

RSpec.configure do |config|
  config.mock_with :rr
end
