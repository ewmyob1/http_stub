describe HttpStub::Server::Stub::Match::Match do

  let(:request)  { instance_double(HttpStub::Server::Request::Request) }
  let(:response) { instance_double(HttpStub::Server::Stub::Response::Base) }
  let(:stub)     { instance_double(HttpStub::Server::Stub::Stub) }

  let(:match) { HttpStub::Server::Stub::Match::Match.new(request, response, stub) }

  describe "#request" do

    it "exposes the provided value" do
      expect(match.request).to eql(request)
    end

  end

  describe "#response" do

    it "exposes the provided value" do
      expect(match.response).to eql(response)
    end

  end

  describe "#stub" do

    it "exposes the provided value" do
      expect(match.stub).to eql(stub)
    end

  end

  describe "#matches?" do

    let(:request_uri)    { "/some/endpoint/uri" }
    let(:request_method) { "GET" }

    let(:criteria_uri)    { request_uri }
    let(:criteria_method) { criteria_method }
    let(:criteria)        { { uri: criteria_uri, method: criteria_method } }
    let(:logger)          { instance_double(Logger) }

    subject { match.matches?(criteria, logger) }

    before(:each) do
      allow(request).to receive(:uri).and_return(request_uri)
      allow(request).to receive(:method).and_return(request_method)
    end

    context "when the uri matches" do

      let(:criteria_uri) { request_uri }

      context "and the criteria method is the same as the results request method" do

        let(:criteria_method) { request_method }

        it "returns true" do
          expect(subject).to be(true)
        end

      end

      context "and the criteria method has different casing than the results request method" do

        let(:criteria_method) { request_method.downcase }

        it "returns true" do
          expect(subject).to be(true)
        end

      end

      context "and the criteria method is different than the results request method" do

        let(:criteria_method) { "POST" }

        it "returns false" do
          expect(subject).to be(false)
        end

      end

    end

    context "when the method matches" do

      let(:criteria_method) { request_method }

      context "and the criteria uri is the same as the results request uri" do

        let(:criteria_uri) { request_uri }

        it "returns true" do
          expect(subject).to be(true)
        end

      end

      context "and the criteria uri partially matches the results request uri" do

        let(:criteria_uri) { "endpoint/uri" }

        it "returns true" do
          expect(subject).to be(true)
        end

      end

      context "and the criteria uri is not within the results request uri" do

        let(:criteria_uri) { "/another/endpoint/uri" }

        it "returns false" do
          expect(subject).to be(false)
        end

      end

    end

  end

  describe "#to_hash" do

    subject { match.to_hash }

    describe "supporting creating a JSON representation of the result" do

      it "contains the matching request" do
        expect(subject).to include(request: request)
      end

      it "contains the served response" do
        expect(subject).to include(response: response)
      end

      it "contains the matched stub" do
        expect(subject).to include(stub: stub)
      end

    end

  end

end
