require_relative 'blotter/version'

module Blotter

  class << self; attr_accessor :blotter_model, :blotter_method; end

  def self.new(request)
    Blotter::Core.new(request)
  end

  def self.register_blotter_model(blotter_model)
    @blotter_model = blotter_model
  end

  def self.register_blotter_method(blotter_method)
    @blotter_method = blotter_method
  end

  class Core

    def initialize(request)
      @request = request
      raise ArgumentError if bad_request?
    end

    def view
      @view ||= instance_eval "page.#{Blotter.blotter_method}"
    end

    def page
      @page ||= Blotter::Page.new(payload['page']['id'])
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

    def initialize
    end
  end

  class Page

    attr_reader :pid

    def initialize(pid)
      @pid = pid
      matched_page_resource
    end

    private

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

    def initialize
    end
  end
end
