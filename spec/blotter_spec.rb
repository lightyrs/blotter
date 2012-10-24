require 'spec_helper'

describe Blotter do

  before do

    Blotter.register_app_id('000')
    Blotter.register_app_secret('wxyz')

    Blotter.register_blotter_model(FacebookPage)
    Blotter.register_blotter_method(:active_giveaway)

    stub(Blotter.blotter_model).columns {[
      OpenStruct.new(type: :string, name: 'pid'),
      OpenStruct.new(type: :integer, name: 'id'),
      OpenStruct.new(type: :boolean, name: 'page_id')
    ]}
  end

  let(:request) {

    OpenStruct.new(
      method: 'POST',
      ip: '127.0.0.1',
      env: {
        'HTTP_ORIGIN' => 'http://apps.facebook.com'
      },
      referrer: 'http://apps.facebook.com/_sg_dev/?fb_source=search&ref=ts&fref=ts',
      params: {
        'signed_request' => 'gibberish',
        'fb_source' => 'search',
        'ref' => 'ts',
        'fref' => 'ts',
        'controller' => 'blotter',
        'action' => 'index'
      },
      cookies: OpenStruct.new(signed: { '_blotter_000_1234_999' => {
        'visitor' => {
          'visit_count' => 7,
          'first_visit' => 2.weeks.ago,
          'last_visit' => 2.days.ago,
          'is_page_fan' => false,
          'is_app_user' => false,
          'became_page_fan' => false,
          'became_app_user' => false,
          'referred_by_ids' => []
        }
      },
      'decoy_cookie' => 'bad' }),
      session: nil
    )
  }

  let(:mock_payload) { { 'page' => { 'id' => '7' } } }

  let(:blotter_instance) { Blotter.new(request) }

  describe ".new" do

    it "acts as an alias for Blotter::Core.new" do
      mock(Blotter::Core).new(request)
      Blotter.new(request)
    end
  end

  describe ".register_app_id" do

  end

  describe ".register_app_secret" do

  end

  describe ".register_blotter_model" do

  end

  describe ".register_blotter_method" do

  end

  describe Blotter::Core do

    let(:bad_source_request) {
      request.clone.tap { |r| r.env['HTTP_ORIGIN'] = 'http://apps.twitter.com' }
    }

    let(:bad_params_request) {
      request.clone.tap { |r| r.params.delete('signed_request') }
    }

    describe "#initialize" do

      it "takes a request object as a required argument" do
        expect { Blotter::Core.new }.to raise_error ArgumentError
        expect { Blotter::Core.new(wrong: 'type') }.to raise_error ArgumentError
        expect { blotter_instance }.to_not raise_error
      end

      it "assigns the request argument to an instance variable" do
        blotter_instance.instance_eval { @request }.should == request
        expect { blotter_instance }.to_not raise_error
      end

      it "raises an error if the request did not originate from facebook.com" do
        expect { Blotter::Core.new(bad_source_request) }.to raise_error
        ArgumentError
      end

      it "raises an error if the request does not have a signed_request param" do
        expect { Blotter::Core.new(bad_params_request) }.to raise_error
        ArgumentError
      end
    end

    describe "#view" do

      let(:page_resource) { FacebookPage.new(name: 'cia') }
      let(:blotter_view_instance) { OpenStruct.new(resource: 1) }

      before do
        any_instance_of(Blotter::Core, payload: mock_payload)
        any_instance_of(Blotter::Page, resource: page_resource)
      end

      it "calls Blotter::View.new with the value of Blotter::Page#resource" do
        mock(Blotter::View).new(page_resource) { blotter_view_instance }
        blotter_instance.view
      end

      it "returns Blotter::View#resource" do
        mock(Blotter::View).new(page_resource) { blotter_view_instance }
        blotter_instance.view.should == 1
      end
    end

    describe "#page" do

      let(:blotter_page_instance) { OpenStruct.new(resource: 2) }

      before do
        any_instance_of(Blotter::Core, payload: mock_payload)
      end

      it "calls Blotter::Page.new with the page id from the signed request" do
        mock(Blotter::Page).new('7') { blotter_page_instance }
        blotter_instance.page
      end

      it "returns Blotter::Page#resource" do
        mock(Blotter::Page).new('7') { blotter_page_instance }
        blotter_instance.page.should == 2
      end
    end

    describe "#visitor" do

      let(:signed_request) { request.params['signed_request'] }
      let(:inbound_cookie) { request.cookies.signed['_blotter_000_1234_999'] }

      let(:blotter_visitor_instance) {

        OpenStruct.new( facebook_uid: '808283',
                        facebook_token: 'wxyz',
                        is_page_fan: true,
                        is_page_admin: false,
                        is_app_user: false,
                        became_page_fan: true,
                        became_app_user: false,
                        visit_count: 7,
                        first_visit: 2.weeks.ago,
                        last_visit: 2.days.ago,
                        referred_by_ids: [] )
      }

      before do
        any_instance_of(Blotter::Core, payload: mock_payload)
        mock(blotter_instance).inbound_cookie { inbound_cookie }
      end

      it "calls Blotter::Visitor.new with signed request and inbound cookie" do
        mock(Blotter::Visitor).new(mock_payload, inbound_cookie) {
          blotter_visitor_instance
        }
        blotter_instance.visitor
      end

      it "returns an instance of Blotter::Visitor" do
        mock(Blotter::Visitor).new(mock_payload, inbound_cookie) {
          blotter_visitor_instance
        }
        blotter_instance.visitor.should == blotter_visitor_instance
      end
    end

    describe "cookie alias methods" do

      let(:blotter_cookie_instance) { OpenStruct.new(inbound: 3, outbound: 4) }

      before do

        any_instance_of(Blotter::Core, payload: mock_payload)

        mock(request).cookies { 'request_cookies' }
        mock(blotter_instance).page { 'page_resource' }
        mock(blotter_instance).view { 'view_resource' }
        mock(blotter_instance).payload { 'payload' }

        mock(Blotter::Cookie).new({
          request_cookies: 'request_cookies',
          page_resource: 'page_resource',
          view_resource: 'view_resource',
          payload: 'payload'
        }) { blotter_cookie_instance }
      end

      describe "#inbound_cookie" do

        it "calls Blotter::Cookie.new with cookies, page, and view arguments" do
          blotter_instance.inbound_cookie
        end

        it "returns Blotter::Cookie#inbound" do
          blotter_instance.inbound_cookie.should == 3
        end
      end

      describe "#outbound_cookie" do

        it "calls Blotter::Cookie.new with cookies, page, and view arguments" do
          blotter_instance.outbound_cookie
        end

        it "returns Blotter::Cookie#outbound" do
          blotter_instance.outbound_cookie.should == 4
        end
      end
    end

    describe "#referral_type" do

      it "returns a string describing the nature of the referral" do
        blotter_instance.referral_type.should == 'search'
      end
    end

    describe "#payload" do

      it "memoizes the parsed signed request" do
        mock(blotter_instance).parsed_request { 2 }
        blotter_instance.payload
        blotter_instance.instance_eval { @parsed_request }.should == 2
      end
    end
  end

  describe Blotter::View do

    let(:page) { FacebookPage.new }
    let(:blotter_view_instance) { Blotter::View.new(page) }

    before do
      stub(page).is_a? { true }
    end

    describe "#initialize" do

      it "takes a Blotter::Page as a required argument" do
        expect { Blotter::View.new }.to raise_error ArgumentError
        expect { Blotter::View.new(request) }.to raise_error ArgumentError
        expect { blotter_view_instance }.to_not raise_error
      end

      it "assigns the page argument to an instance variable" do
        blotter_view_instance.instance_eval { @page }.should == page
      end
    end

    describe "#resource" do

      it "returns the return value of the blotter_model's blotter_method" do
        mock(page).active_giveaway { 'ponies' }
        blotter_view_instance.resource.should == 'ponies'
      end
    end
  end

  describe Blotter::Page do

    let(:pid) { '1234' }
    let(:blotter_page_instance) { Blotter::Page.new(pid) }

    describe "#initialize" do

      it "takes a facebook page id as a required argument" do
        expect { Blotter::Page.new }.to raise_error ArgumentError
        expect { Blotter::Page.new(request) }.to raise_error ArgumentError
        expect { blotter_page_instance }.to_not raise_error
      end

      it "assigns the facebook page id to an instance variable" do
        blotter_page_instance.instance_eval { @pid }.should == pid
      end
    end

    describe "#resource" do

      it "returns an instance of the blotter model with the provided pid" do
        mock(FacebookPage).find_by_pid(1234) { 'ponies' }
        blotter_page_instance.resource.should == 'ponies'
      end
    end
  end

  describe Blotter::Visitor do

    describe "#initialize" do

    end
  end

  describe Blotter::Cookie do

    let(:args) { { request_cookies: request.cookies,
                   page_resource: OpenStruct.new(id: 1234),
                   view_resource: OpenStruct.new(id: 999),
                   payload: {
                     'page' => { 'has_liked' => true, 'admin' => false },
                     'user_id' => '808283'
                   } } }

    let(:blotter_cookie_instance) { Blotter::Cookie.new(args) }

    describe "#initialize" do

      it "takes a hash with cookies, page, and view as a required argument" do
        expect { Blotter::Cookie.new }.to raise_error ArgumentError
        expect { Blotter::Cookie.new("bad") }.to raise_error ArgumentError
        expect { blotter_cookie_instance }.to_not raise_error
      end

      it "assigns the options hash to an instance variable" do
        blotter_cookie_instance.instance_eval { @options }.should == args
      end
    end

    describe "#inbound" do

      it "extracts the relevant blotter cookie from the request cookies" do
        blotter_cookie_instance.inbound.should == request.cookies
        .signed['_blotter_000_1234_999']
      end
    end

    describe "#outbound" do

      before do
        Timecop.freeze
      end

      after do
        Timecop.return
      end

      it "returns Blotter::Cookie#outbound_cookie_value" do
        blotter_cookie_instance.outbound.should == {
          'visitor' => {
            'visit_count' => 8,
            'first_visit' => 2.weeks.ago,
            'last_visit' => Time.now,
            'is_page_fan' => true,
            'is_app_user' => true,
            'became_page_fan' => true,
            'became_app_user' => true,
            'referred_by_ids' => []
          }
        }
      end
    end
  end
end
