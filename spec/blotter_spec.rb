# encoding: utf-8
require 'spec_helper'
require 'ostruct'

describe Blotter do

  let(:request) {
    OpenStruct.new(
      method: "POST",
      ip: "127.0.0.1",
      source: "http://apps.facebook.com",
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
    request.clone.tap { |r| r.source = "http://apps.twitter.com" }
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

    let(:fake_page_data) { { 'page' => 'fake page data' } }

    before do
      blotter_instance.stub(:payload).and_return fake_page_data
    end

    it "returns page data from the parsed signed request" do
      blotter_instance.should_receive(:payload)
      blotter_instance.page.should == 'fake page data'
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