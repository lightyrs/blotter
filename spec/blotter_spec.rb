require 'spec_helper'

describe Blotter do

  before do

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
      method: "POST",
      ip: "127.0.0.1",
      env: {
        "HTTP_ORIGIN" => "http://apps.facebook.com"
      },
      referrer: "http://apps.facebook.com/_sg_dev/?fb_source=search&ref=ts&fref=ts",
      params: {
        "signed_request" => "gibberish",
        "fb_source" => "search",
        "ref" => "ts",
        "fref" => "ts",
        "controller" => "blotter",
        "action" => "index"
      },
      cookies: nil,
      session: nil
    )
  }

  let(:blotter_instance) { Blotter.new(request) }

  describe ".new" do

    it "acts as an alias for Blotter::Core.new" do
      mock(Blotter::Core).new(request)
      Blotter.new(request)
    end
  end

  describe Blotter::Core do

    let(:bad_source_request) {
      request.clone.tap { |r| r.env["HTTP_ORIGIN"] = "http://apps.twitter.com" }
    }

    let(:bad_params_request) {
      request.clone.tap { |r| r.params.delete("signed_request") }
    }

    describe "#initialize" do

      it "takes a request object as a required argument" do
        expect { Blotter::Core.new }.to raise_error ArgumentError
        expect { Blotter::Core.new({ wrong: "type" }) }.to raise_error ArgumentError
        expect { Blotter::Core.new(request) }.to_not raise_error
      end

      it "assigns the request argument to an instance variable" do
        Blotter::Core.new(request).instance_eval { @request }.should == request
      end

      it "raises an error if the request did not originate from facebook.com" do
        expect { Blotter::Core.new(bad_source_request) }.to raise_error
        ArgumentError
        expect { Blotter::Core.new(request).to_not raise_error }
      end

      it "raises an error if the request does not have a signed_request param" do
        expect { Blotter::Core.new(bad_params_request) }.to raise_error
        ArgumentError
        expect { Blotter::Core.new(request).to_not raise_error }
      end
    end

    describe "#page" do

      before do
        any_instance_of(Blotter::Core, :payload => {
          'page' => { 'id' => '7' }
        })
      end

      it "calls Blotter::Page.new with the page id from the signed request" do
        mock(Blotter::Page).new('7') { 'facebook page resource' }
        blotter_instance.page.should == 'facebook page resource'
      end
    end

    describe "#visitor" do

      before do
        any_instance_of(Blotter::Core, :payload => {
          'user' => { 'data' => 'fake visitor data' },
          'user_id' => '808283'
        })
      end

      it "returns visitor data from the parsed signed request" do
        blotter_instance.visitor.should == { 'data' => 'fake visitor data',
                                             'uid' => '808283' }
      end
    end

    describe "#referral_type" do

      it "returns a string describing the nature of the referral" do
        blotter_instance.referral_type.should == "search"
      end
    end

    describe "#payload" do

      it "memoizes the parsed signed request" do
        mock(blotter_instance).parsed_request
        blotter_instance.payload
      end
    end
  end

  describe Blotter::Visitor do

    describe "#initialize" do

    end
  end

  describe Blotter::Page do

    let(:pid) { '1234' }

    describe "#initialize" do

      it "takes a facebook page id as a required argument" do
        expect { Blotter::Page.new }.to raise_error ArgumentError
        expect { Blotter::Page.new(request) }.to raise_error ArgumentError
        expect { Blotter::Page.new(pid) }.to_not raise_error
      end

      it "assigns the facebook page id to an instance variable" do
        blotter_page_instance = Blotter::Page.new(pid)
        blotter_page_instance.instance_eval { @pid }.should == pid
      end

      it "returns an instance of the blotter model with the provided pid" do

      end
    end
  end

  describe Blotter::View do

    let(:page) { FacebookPage.new }

    before do
      stub(page).is_a? { true }
    end

    describe "#initialize" do

      it "takes a Blotter::Page as a required argument" do
        expect { Blotter::View.new }.to raise_error ArgumentError
        expect { Blotter::View.new(request) }.to raise_error ArgumentError
        expect { Blotter::View.new(page) }.to_not raise_error
      end

      it "assigns the page argument to an instance variable" do
        blotter_view_instance = Blotter::View.new(page)
        blotter_view_instance.instance_eval { @page }.should == page
      end
    end
  end

  describe Blotter::Cookie do

    describe "#initialize" do

    end

    describe "#inbound" do

    end

    describe "#outbound" do

    end

    describe "#cookie_key" do

    end
  end
end
