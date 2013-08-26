require "blotter/version"
require "blotter/railtie" if defined?(Rails)

module Blotter
  extend ActiveSupport::Concern

  included do
    prepend_before_filter :assign_blotter, Blotter.blotter_controller_actions

    def assign_blotter
      @blotter = Blotter.new(request)
    end
  end

  class << self

    attr_accessor :app_id, :app_secret
    attr_accessor :blotter_model, :blotter_method, :blotter_controller_actions

    def new(request)
      Blotter::Core.new(request)
    end

    def register_app_id(app_id)
      @app_id = app_id
    end

    def register_app_secret(app_secret)
      @app_secret = app_secret
    end

    def register_blotter_model(blotter_model)
      @blotter_model = blotter_model
    end

    def register_blotter_method(blotter_method)
      @blotter_method = blotter_method
    end

    def register_controller_actions(controller_actions = {})
      @blotter_controller_actions = controller_actions
      puts @blotter_controller_actions.inspect
    end
  end

  # Blotter::Core
  # The public API
  #
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
      @page ||= Blotter::Page.new(pid)
      @page.resource
    end

    def visitor
      @visitor ||= Blotter::Visitor.new(
        request: @request,
        page_resource: page,
        view_resource: view,
        payload: payload
      )
    end

    def inbound_cookie
      cookie.inbound
    end

    def outbound_cookie
      cookie.outbound
    end

    def referral_type
      @request.params['fb_source'] ? @request.params['fb_source'].to_sym : :tab
    end

    def payload
      @parsed_request ||= parsed_request
    end

    def pid
      if payload
        payload['page']['id']
      elsif referral_type
        0
      end
    end

    private

    def parsed_request
      @oauth ||= Koala::Facebook::OAuth.new(Blotter.app_id, Blotter.app_secret)
      @oauth.parse_signed_request(@request.params['signed_request'])
    rescue NoMethodError
      false
    end

    def cookie
      @cookie ||= Blotter::Cookie.new(visitor)
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

  # Blotter::View
  # The resource used to populate the view
  #
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
    rescue NoMethodError
      true
    end
  end

  # Blotter::Page
  # The Facebook page resource being requested
  #
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
    rescue NoMethodError
      true
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
      /page_id|pid|facebook_id|facebook_page_id|facebook_pid|
      fb_pid|fb_page_id|fb_id|fbid|fbpid|fid|fpid/
    end
  end

  # Blotter::Visitor
  # The visitor and his/her context
  #
  class Blotter::Visitor

    attr_accessor :inbound_cookie

    def initialize(args)
      @options = args
      raise ArgumentError if bad_args?
      @inbound_cookie ||= cookie_jar.signed[cookie_key]
    end

    def uid
      @options[:payload]['user_id'] rescue nil
    end

    def visit_count
      initial? ? 1 : inbound_visitor.visit_count + 1
    end

    def first_visit
      initial? ? Time.now : inbound_visitor.first_visit
    end

    def last_visit
      initial? ? Time.now : inbound_visitor.last_visit
    end

    def is_new?
      initial?
    end

    def is_returning?
      true unless initial?
    end

    def is_page_admin?
      @options[:payload]['page']['admin'] rescue false
    end

    def is_page_fan?
      @options[:payload]['page']['liked'] rescue false
    end

    def is_app_user?
      @options[:payload].has_key? 'user_id' rescue false
    end

    def became_page_fan?
      just_became_page_fan? or inbound_visitor.became_page_fan rescue false
    end

    def became_app_user?
      just_became_app_user? or inbound_visitor.became_app_user rescue false
    end

    def just_became_page_fan?
      return false if initial?
      is_page_fan? and inbound_visitor.is_page_fan == false
    end

    def just_became_app_user?
      return false if initial?
      is_app_user? and inbound_visitor.is_app_user == false
    end

    def referred_by_ids
      return inbound_referrer_ids if initial?
      inbound_visitor.referred_by_ids.push(inbound_referrer_ids).compact
    end

    private

    def initial?
      inbound_cookie.nil?
    end

    def cookie_key
      app_id = Blotter.app_id
      page_id = @options[:page_resource].id
      view_id = @options[:view_resource].id
      @cookie_key ||= "_blotter_#{app_id}_#{page_id}_#{view_id}"
    end

    def cookie_jar
      ActionDispatch::Cookies::CookieJar.build(@options[:request])
    end

    def inbound_visitor
      initial? ? nil : OpenStruct.new(inbound_cookie['visitor'])
    end

    def inbound_referrer_ids
      []
    end

    def bad_args?
      true unless @options.is_a? Hash
    rescue NoMethodError
      true
    end
  end

  # Blotter::Cookie
  # The inbound and outbound cookies
  #
  class Blotter::Cookie

    attr_accessor :cookie_key

    def initialize(blotter_visitor)
      @visitor = blotter_visitor
      raise ArgumentError if bad_args?
    end

    def inbound
      @visitor.inbound_cookie
    end

    def outbound
      outbound_cookie_value
    end

    private

    def outbound_cookie_value

      cookie_value = {}
      cookie_value['visitor'] = {
        'visit_count' => @visitor.visit_count,
        'first_visit' => @visitor.first_visit,
        'last_visit' => @visitor.last_visit,
        'is_page_fan' => @visitor.is_page_fan?,
        'is_app_user' => @visitor.is_app_user?,
        'became_page_fan' => @visitor.became_page_fan?,
        'became_app_user' => @visitor.became_app_user?,
        'referred_by_ids' => @visitor.referred_by_ids
      }

      cookie_value
    end

    def bad_args?
      true unless @visitor.is_a? Blotter::Visitor
    rescue NoMethodError
      true
    end
  end
end
