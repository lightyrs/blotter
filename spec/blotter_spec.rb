# encoding: utf-8
require_relative '../spec/spec_helper'
require 'ostruct'

describe Blotter do

  before do
    Blotter.register_blotter_model(FacebookPage)
    Blotter.register_blotter_method(:active_giveaway)
    Blotter.blotter_model.stub(:columns).and_return([
      OpenStruct.new(type: :string, name: 'pid'),
      OpenStruct.new(type: :integer, name: 'id'),
      OpenStruct.new(type: :boolean, name: 'page_id')
    ])
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

  let(:bad_source_request) {
    request.clone.tap { |r| r.env["HTTP_ORIGIN"] = "http://apps.twitter.com" }
  }

  let(:bad_params_request) {
    request.clone.tap { |r| r.params.delete("signed_request") }
  }

  let(:blotter_instance) { Blotter.new(request) }

  describe ".new" do

    it "acts as an alias for Blotter::Core.new" do
      Blotter::Core.should_receive(:new).with(request)
      Blotter.new(request)
    end
  end

  describe Blotter::Core do

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

      it "calls Blotter::Page.new with the page id from the signed request" do

      end

      it "returns an instance of Blotter::Page" do

      end
    end

    describe "#visitor" do

      let(:fake_visitor_data) {
        {
          'user' => { 'data' => 'fake visitor data' },
          'user_id' => '808283'
        }
      }

      before do
        blotter_instance.stub(:payload).and_return fake_visitor_data
      end

      it "returns visitor data from the parsed signed request" do
        blotter_instance.should_receive(:payload)
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
        blotter_instance.should_receive(:parsed_request)
        blotter_instance.payload
      end
    end
  end

  describe Blotter::Visitor do

    describe "#initialize" do

    end
  end

  describe Blotter::Page do

    describe "#initialize" do

      it "takes a facebook page id as a required argument" do

      end

      it "assigns the facebook page id to an instance variable" do

      end

      it "returns an instance of the blotter model with the provided pid" do

      end
    end
  end

  describe Blotter::Art do

    let(:page) { mock 'Blotter::Page' }
    let(:visitor) { mock 'Blotter::Visitor' }

    before do
      page.stub(:is_a?).and_return true
      visitor.stub(:is_a?).and_return true
    end

    describe "#initialize" do

      it "takes a Blotter::Page and Blotter::Visitor as required arguments" do
        expect { Blotter::Art.new }.to raise_error ArgumentError
        expect { Blotter::Art.new(request, 2) }.to raise_error ArgumentError
        expect { Blotter::Art.new(page, visitor) }.to_not raise_error
      end

      it "assigns the page and visitor arguments to instance variables" do
        blotter_art_instance = Blotter::Art.new(page, visitor)
        blotter_art_instance.instance_eval { @page }.should == page
        blotter_art_instance.instance_eval { @visitor }.should == visitor
      end
    end
  end

  # TODO
  # How do we find the right cookie?  This would require prior knowledge of the
  # active resource, which implies a method for retrieving the active resource
  # from the discerned page that generated the request.
  #
  # Could have some macro like:
  # blotter :active_giveaway
  #
  # This means, once we find the page, we call :active_giveaway on it to
  # retrieve the active resource.

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
