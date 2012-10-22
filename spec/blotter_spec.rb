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
end