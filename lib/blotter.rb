require_relative 'blotter/version'

module Blotter

  class << self

    attr_accessor :blotter_model, :blotter_method
    attr_accessor :app_id, :app_secret

    def new(request)
      Blotter::Core.new(request)
    end

    def register_blotter_model(blotter_model)
      @blotter_model = blotter_model
    end

    def register_blotter_method(blotter_method)
      @blotter_method = blotter_method
    end
  end

  class Core

    def initialize(request)
      @request = request
      raise ArgumentError if bad_request?
    end

    def view
      @view ||= Blotter::View.new(page)
      @view.resource
    end

    def page
      @page ||= Blotter::Page.new(payload['page']['id'])
      @page.resource
    end

    def visitor
      visitor = payload['user']
      visitor.merge!("uid" => payload['user_id']) if payload.has_key? 'user_id'
    end

    def outbound_cookie
      @cookie ||= Blotter::Cookie.new(
        request_cookies: @request.cookies,
        page_resource: page,
        view_resource: view
      )
      @cookie.outbound
    end

    def referral_type
      @request.params['fb_source']
    end

    def payload
      @parsed_request ||= parsed_request
    end

    private

    def parsed_request
      @oauth ||= Koala::Facebook::OAuth.new(Blotter.app_id, Blotter.app_secret)
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

  class View

    def initialize(page)
      @page = page
      raise ArgumentError if bad_args?
    end

    def resource
      matched_view_resource
    end

    private

    def matched_view_resource
      instance_eval "@page.#{Blotter.blotter_method}"
    end

    def bad_args?
      true unless @page.is_a? Blotter.blotter_model
    end
  end

  class Page

    attr_reader :pid

    def initialize(pid)
      @pid = pid
      raise ArgumentError if bad_args?
    end

    def resource
      matched_page_resource
    end

    private

    def bad_args?
      true unless @pid.is_a? String or @pid.is_a? Integer
    end

    def matched_page_resource
      dirty_results = likely_pid_columns.map do |column_name|
        begin
          Blotter.blotter_model.class_eval("find_by_#{column_name}(#{@pid})")
        rescue NoMethodError
          next
        end
      end
      dirty_results.compact.pop
    end

    def likely_pid_columns
      columns = Blotter.blotter_model.columns.select do |column|
        eligible_column? column
      end
      columns.map(&:name)
    end

    def eligible_column?(column)
      [:string, :integer, :text].include? column.type and column.name =~
          common_pid_column_names
    end

    def common_pid_column_names
      /page_id|pid|facebook_id|facebook_page_id|facebook_pid|fb_pid|fb_page_id|fb_id|fbid|fbpid|fid|fpid/
    end
  end

  class Visitor

    def initialize
    end
  end

  class Cookie

    attr_accessor :cookie_key

    def initialize(args)
      @options = args
      raise ArgumentError if bad_args?
    end

    def inbound
      @inbound ||= @options[:request_cookies].signed[cookie_key]
    end

    def outbound
      outbound_cookie_value
    end

    private

    def cookie_key
      @cookie_key ||= "_blotter_#{Blotter.app_id}_#{options[:page_resource]
      .id}_#{options[:view_resource].id}"
    end

    def outbound_cookie_value

      cookie_value = {}

      cookie_value['visitor']['visit_count'] = visitor_visit_count
      cookie_value['visitor']['first_visit'] = visitor_first_visit
      cookie_value['visitor']['last_visit'] = visitor_last_visit

      cookie_value['visitor']['is_page_fan'] = visitor_is_page_fan?
      cookie_value['visitor']['is_app_user'] = visitor_is_app_user?
      cookie_value['visitor']['became_page_fan'] = visitor_became_page_fan?
      cookie_value['visitor']['became_app_user'] = visitor_became_app_user?

      cookie_value['visitor']['referred_by_ids'] = visitor_referred_by_ids
    end

    def visitor_visit_count
      @inbound
    end

    def visitor_first_visit
      @inbound
    end

    def visitor_last_visit
      @inbound
    end

    def visitor_is_page_fan?
      @inbound
    end

    def visitor_is_app_user?
      @inbound
    end

    def visitor_became_page_fan?
      @inbound
    end

    def visitor_became_app_user?
      @inbound
    end

    def visitor_referred_by_ids
      @inbound
    end

    def bad_args?
      true unless @options.is_a? Hash
    end
  end
end
