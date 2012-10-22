require_relative 'blotter/version'

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
      @request.env && @request.env['HTTP_ORIGIN'].match(/facebook\.com$/)
    end

    def expected_params?
      @request.params['signed_request'].length > 0
    end
  end

  class Visitor

  end

  class Page

  end

  class Art

    def initialize(page, visitor)
      @page, @visitor = page, visitor
      raise ArgumentError if bad_args?
    end

    private

    def bad_args?
      true unless @page.is_a? Blotter::Page and @visitor.is_a? Blotter::Visitor
    end
  end

  class Cookie


  end
end
