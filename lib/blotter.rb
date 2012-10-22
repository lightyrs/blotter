require "blotter/version"

module Blotter

  def self.new(request)
    Blotter::Core.new(request)
  end

  class Core

    def initialize(request)
      @request = request
      raise ArgumentError if bad_request?
    end

    def page
      payload['page']
    end

    def visitor
      visitor = payload['user']
      visitor.merge!("uid" => payload['user_id']) if payload.has_key? 'user_id'
    end

    def referral_type
      @request.params['fb_source']
    end

    def payload
      @parsed_request ||= parsed_request
    end

    private

    def parsed_request
      @oauth ||= Koala::Facebook::OAuth.new(FB_APP_ID, FB_APP_SECRET)
      @oauth.parse_signed_request(@request.params['signed_request'])
    end

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
