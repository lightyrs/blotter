require 'spec_helper'

describe Blotter do

  before do

    Blotter.register_app_id('000')
    Blotter.register_app_secret('wxyz')

    Blotter.register_blotter_model(FacebookPage)
    Blotter.register_blotter_method(:active_giveaway)
  end

  let(:request) {

    OpenStruct.new(
      method: 'POST',
      ip: '127.0.0.1',
      env: {
        'HTTP_ORIGIN' => 'http://apps.facebook.com'
      },
      referrer: 'http://apps.facebook.com/_sg/?fb_source=search&ref=ts&fref=ts',
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
          'is_app_user' => true,
          'became_page_fan' => false,
          'became_app_user' => true,
          'referred_by_ids' => [] }
        },
        'decoy_cookie' => 'bad'
      }),
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

    it "assigns the app_id argument to an instance variable" do
      Blotter.register_app_id('1234')
      Blotter.app_id.should == '1234'
    end
  end

  describe ".register_app_secret" do

    it "assigns the app_secret argument to an instance variable" do
      Blotter.register_app_secret('wxyz')
      Blotter.app_secret.should == 'wxyz'
    end
  end

  describe ".register_blotter_model" do

    it "assigns the blotter_model argument to an instance variable" do
      Blotter.register_blotter_model(FacebookPage)
      Blotter.blotter_model.should == FacebookPage
    end
  end

  describe ".register_blotter_method" do

    it "assigns the blotter_method argument to an instance variable" do
      Blotter.register_blotter_method(:active_giveaway)
      Blotter.blotter_method.should == :active_giveaway
    end
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

      it "raises an error if the request doesn't have a signed_request param" do
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
        any_instance_of(Blotter::Core, pid: '777')
      end

      it "calls Blotter::Page.new with the page id from the signed request" do
        mock(Blotter::Page).new('777') { blotter_page_instance }
        blotter_instance.page
      end

      it "returns Blotter::Page#resource" do
        mock(Blotter::Page).new('777') { blotter_page_instance }
        blotter_instance.page.should == 2
      end
    end

    describe "#visitor" do

      let(:args) { { request: request,
                     page_resource: OpenStruct.new(id: 1234),
                     view_resource: OpenStruct.new(id: 999),
                     payload: mock_payload } }

      let(:blotter_visitor_instance) { "visitor" }

      before do
        mock(blotter_instance).page { OpenStruct.new(id: 1234) }
        mock(blotter_instance).view { OpenStruct.new(id: 999) }
        mock(blotter_instance).payload { mock_payload }
      end

      it "calls Blotter::Visitor.new with required args" do
        mock(Blotter::Visitor).new(args) {
          blotter_visitor_instance
        }
        blotter_instance.visitor
      end

      it "returns an instance of Blotter::Visitor" do
        mock(Blotter::Visitor).new(args) {
          blotter_visitor_instance
        }
        blotter_instance.visitor.should == blotter_visitor_instance
      end
    end

    describe "cookie alias methods" do

      let(:blotter_cookie_instance) { OpenStruct.new(inbound: 3, outbound: 4) }

      before do
        mock(blotter_instance).cookie { blotter_cookie_instance }
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
        blotter_instance.referral_type.should == :search
      end
    end

    describe "#payload" do

      it "memoizes the parsed signed request" do
        mock(blotter_instance).parsed_request { 2 }
        blotter_instance.payload
        blotter_instance.instance_eval { @parsed_request }.should == 2
      end
    end

    describe "#pid" do

      context "when the payload is present" do

        it "returns the facebook page id from the payload" do
          mock(blotter_instance).payload.times(2) {
            { 'page' => { 'id' => '234234141' } }
          }
          blotter_instance.pid.should == '234234141'
        end
      end

      context "when the referral type is not :tab" do

        it "returns the facebook page id from the relevant method" do
          mock(blotter_instance).payload { false }
          mock(blotter_instance).referral_type { :apprequest }
          blotter_instance.pid
        end
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

      before do
        stub(Blotter.blotter_model).columns {[
          OpenStruct.new(type: :string, name: 'pid'),
          OpenStruct.new(type: :integer, name: 'id'),
          OpenStruct.new(type: :boolean, name: 'page_id')
        ]}
      end

      it "returns an instance of the blotter model with the provided pid" do
        mock(FacebookPage).find_by_pid(1234) { 'ponies' }
        blotter_page_instance.resource.should == 'ponies'
      end
    end
  end

  describe Blotter::Visitor do

    let(:args) { { request: request,
                   page_resource: OpenStruct.new(id: 1234),
                   view_resource: OpenStruct.new(id: 999),
                   payload: {
                     'page' => { 'liked' => true, 'admin' => false },
                     'user_id' => '808283'
                   } } }

    let(:blotter_visitor_instance) { Blotter::Visitor.new(args) }

    before do
      Timecop.freeze
      mock(ActionDispatch::Cookies::CookieJar).build(request){ request.cookies }
    end

    after do
      Timecop.return
    end

    describe "#initialize" do

      it "takes a hash with cookies, page, and view as a required argument" do
        expect { Blotter::Visitor.new }.to raise_error ArgumentError
        expect { Blotter::Visitor.new("bad") }.to raise_error ArgumentError
        expect { blotter_visitor_instance }.to_not raise_error
      end

      it "assigns the options hash to an instance variable" do
        blotter_visitor_instance.instance_eval { @options }.should == args
      end
    end

    subject { blotter_visitor_instance }

    describe "#uid" do
      its(:uid) { should == '808283' }
    end

    describe "#visit_count" do
      its(:visit_count) { should == 8 }
    end

    describe "#first_visit" do
      its(:first_visit) { should == 2.weeks.ago }
    end

    describe "#last_visit" do
      its(:last_visit) { should == 2.days.ago }
    end

    describe "#is_new?" do
      its(:is_new?) { should be_false }
    end

    describe "#is_returning?" do
      its(:is_returning?) { should be_true }
    end

    describe "#is_page_admin?" do
      its(:is_page_admin?) { should be_false }
    end

    describe "#is_page_fan?" do
      its(:is_page_fan?) { should be_true }
    end

    describe "#is_app_user?" do
      its(:is_app_user?) { should be_true }
    end

    describe "#became_page_fan?" do
      its(:became_page_fan?) { should be_true }
    end

    describe "#became_app_user?" do
      its(:became_app_user?) { should be_true }
    end

    describe "#just_became_page_fan?" do
      its(:just_became_page_fan?) { should be_true }
    end

    describe "#just_became_app_user?" do
      its(:just_became_app_user?) { should be_false }
    end

    describe "#referred_by_ids" do
      its(:referred_by_ids) { should == [] }
    end
  end

  describe Blotter::Cookie do

    let(:blotter_visitor) {

      OpenStruct.new(
        'inbound_cookie' => 333,
        'uid' => '808283',
        'visit_count' => 8,
        'first_visit' => 2.weeks.ago,
        'last_visit' => Time.now,
        'is_new?' => false,
        'is_returning?' => true,
        'is_page_admin?' => false,
        'is_page_fan?' => true,
        'is_app_user?' => true,
        'became_page_fan?' => true,
        'became_app_user?' => true,
        'just_became_page_fan?' => true,
        'just_became_app_user?' => false,
        'referred_by_ids' => []
      )
    }

    let(:blotter_cookie_instance) { Blotter::Cookie.new(blotter_visitor) }

    before do
      Timecop.freeze
      mock(blotter_visitor).is_a?(Blotter::Visitor) { true }
    end

    after do
      Timecop.return
    end

    describe "#initialize" do

      it "takes a Blotter::Visitor object as a required argument" do
        expect { Blotter::Cookie.new }.to raise_error ArgumentError
        expect { Blotter::Cookie.new("bad") }.to raise_error ArgumentError
        expect { blotter_cookie_instance }.to_not raise_error
      end

      it "assigns the Blotter::Visitor object to an instance variable" do
        blotter_cookie_instance.instance_eval { @visitor }.should ==
            blotter_visitor
      end
    end

    describe "#inbound" do

      it "acts as an alias for the assigned Blotter::Visitor object" do
        blotter_cookie_instance.inbound.should == 333
      end
    end

    describe "#outbound" do

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
