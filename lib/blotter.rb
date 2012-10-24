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

    def register_app_id(app_id)
      @app_id = app_id
    end

    def register_app_secret(app_secret)
      @app_secret = app_secret
    end
  end

  class Blotter::Core

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
      @visitor ||= Blotter::Visitor.new(payload, inbound_cookie)
    end

    def inbound_cookie
      cookie.inbound
    end

    def outbound_cookie
      cookie.outbound
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

    def cookie
      @cookie ||= Blotter::Cookie.new(
        request_cookies: @request.cookies,
        page_resource: page,
        view_resource: view
      )
    end

    def bad_request?
      true unless expected_object? and expected_source? and expected_params?
    end

    def expected_object?
      @request.respond_to?('params')
    rescue NoMethodError
      false
    end

    def expected_source?
      @request.env && @request.env['HTTP_ORIGIN'].include?('facebook.com')
    rescue NoMethodError
      false
    end

    def expected_params?
      @request.params['signed_request'].length > 0
    rescue NoMethodError
      false
    end
  end

  class Blotter::View

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

  class Blotter::Page

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

  class Blotter::Visitor

    def initialize(payload, inbound_cookie)
      @payload, @inbound_cookie = payload, inbound_cookie
      raise ArgumentError if bad_args?
    end

    private

    def bad_args?
      true unless @payload.is_a? Hash and @payload.respond_to? 'user'
    end
  end

  class Blotter::Cookie

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

    def initial?
      inbound.nil?
    end

    def cookie_key
      app_id = Blotter.app_id
      page_id = @options[:page_resource].id
      view_id = @options[:view_resource].id
      @cookie_key ||= "_blotter_#{app_id}_#{page_id}_#{view_id}"
    end

    def outbound_cookie_value

      cookie_value = {}

      cookie_value['visitor']['visit_count'] = visitor_visit_count
      cookie_value['visitor']['first_visit'] = visitor_first_visit
      cookie_value['visitor']['last_visit'] = visitor_last_visit

      cookie_value['visitor']['is_page_fan'] = visitor_is_page_fan?
      cookie_value['visitor']['is_page_admin'] = visitor_is_page_admin?
      cookie_value['visitor']['is_app_user'] = visitor_is_app_user?
      cookie_value['visitor']['became_page_fan'] = visitor_became_page_fan?
      cookie_value['visitor']['became_app_user'] = visitor_became_app_user?

      cookie_value['visitor']['referred_by_ids'] = visitor_referred_by_ids
    end

    def visitor_visit_count
      initial? ? 1 : inbound['visitor']['visit_count'] + 1
    end

    def visitor_first_visit
      initial? ? Time.now : inbound['visitor']['first_visit']
    end

    def visitor_last_visit
      Time.now
    end

    def visitor_is_page_fan?
      @options[:payload]['page']['has_liked'] rescue false
    end

    def visitor_is_page_admin?
      @options[:payload]['page']['admin'] rescue false
    end

    def visitor_is_app_user?
      @options[:payload].has_key? 'user_id' rescue false
    end

    def visitor_became_page_fan?
      return false if initial?
      visitor_is_page_fan? and inbound['visitor']['is_page_fan'] == false
    end

    def visitor_became_app_user?
      return false if initial?
      visitor_is_app_user? and inbound['visitor']['is_app_user'] == false
    end

    def visitor_referred_by_ids
      return referred_by_ids if initial?
      inbound['visitor']['referred_by_ids'].push(referred_by_ids)
    end

    def referred_by_ids
      
    end

    def bad_args?
      true unless @options.is_a? Hash
    end
  end
end
