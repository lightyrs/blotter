require "blotter/version"

module Blotter

  class Core

    def initialize(request)
      @request = request
      raise ArgumentError if bad_request?
    end

    private

    def bad_request?
      true unless expected_object? and expected_source? and expected_params?
    end

    def expected_object?
      @request.respond_to? 'params'
    end

    def expected_source?
      @request.source.match /facebook\.com$/
    end

    def expected_params?
      @request.params['signed_request'].length > 0
    end
  end
end
