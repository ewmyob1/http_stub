describe "Stub match acceptance" do
  include_context "configurer integration"

  before(:example) { configurer.initialize! }

  after(:example) { configurer.clear_stubs! }

  describe "GET /http_stub/stubs/matches" do

    let(:request_uri)        { "/some/uri" }
    let(:request_method)     { :get }
    let(:request_headers)    do
      (1..3).reduce({}) { |result, i| result.tap { result["request_header_#{i}"] = "request header value #{i}" } }
    end
    let(:request_parameters) { {} }
    let(:request_body)       { nil }

    let(:response)          { HTTParty.get("#{server_uri}/http_stub/stubs/matches") }
    let(:response_document) { Nokogiri::HTML(response.body) }

    shared_context "registers a stub" do

      let(:stub_response_status)  { 203 }
      let(:stub_response_headers) do
        (1..3).reduce({}) { |result, i| result.tap { result["response_header_#{i}"] = "response header value #{i}" } }
      end
      let(:stub_response_body)    { "Stub response body" }

      def register_stub
        @register_stub_response = stub_server.add_stub!(build_stub)
      end

      def build_stub
        stub_server.build_stub do |stub|
          stub.match_requests(uri: request_uri, method: request_method,
                              headers: request_headers, parameters: request_parameters, body: request_body)
          stub.respond_with(status: stub_response_status, headers: stub_response_headers, body: stub_response_body)
        end

      end

    end

    shared_context "behaviours of a request that is recorded in the stub match log" do

      it "returns a response body that contains the uri of the request" do
        expect(response.body).to match(/#{escape_html(request_uri)}/)
      end

      it "returns a response body that contains the method of the request" do
        expect(response.body).to match(/#{escape_html(request_method)}/)
      end

      it "returns a response body that contains the headers of the request whose names are in uppercase" do
        request_headers.each do |expected_header_key, expected_header_value|
          expect(response.body).to match(/#{expected_header_key.upcase}:#{expected_header_value}/)
        end
      end

      context "when the request contains parameters" do

        let(:request_parameters) do
          (1..3).reduce({}) { |result, i| result.tap { result["parameter_#{i}"] = "parameter value #{i}" } }
        end

        it "returns a response body that contain the parameters" do
          request_parameters.each do |expected_parameter_key, expected_parameter_value|
            expect(response.body).to match(/#{expected_parameter_key}=#{expected_parameter_value}/)
          end
        end

        def issue_request
          HTTParty.send(
            request_method, "#{server_uri}#{request_uri}", headers: request_headers, query: request_parameters
          )
        end

      end

      context "when the request contains a body" do

        let(:request_body) { "Some <strong>request body</strong>" }

        it "returns a response body that contains the body" do
          expect(response.body).to match(/#{escape_html(request_body)}/)
        end

        def issue_request
          HTTParty.send(request_method, "#{server_uri}#{request_uri}", headers: request_headers, body: request_body)
        end

      end

      def issue_request
        HTTParty.send(request_method, "#{server_uri}#{request_uri}", headers: request_headers)
      end

    end

    context "when a request has been made matching a stub" do

      include_context "registers a stub"

      before(:example) do
        register_stub

        issue_request
      end

      include_context "behaviours of a request that is recorded in the stub match log"

      it "returns a response body that contains stub response status" do
        expect(response.body).to match(/#{escape_html(stub_response_status)}/)
      end

      it "returns a response body that contains stub response headers" do
        stub_response_headers.each do |expected_header_key, expected_header_value|
          expect(response.body).to match(/#{expected_header_key}:#{expected_header_value}/)
        end
      end

      it "returns a response body that contains stub response body" do
        expect(response.body).to match(/#{escape_html(stub_response_body)}/)
      end

      it "returns a response body that contains a link to the matched stub" do
        stub_link = response_document.css("a.stub").first
        expect(full_stub_uri).to end_with(stub_link["href"])
      end

      def full_stub_uri
        @register_stub_response.header["location"]
      end

    end

    context "when a request has been made that does not match a stub" do

      before(:example) { issue_request }

      it_behaves_like "behaviours of a request that is recorded in the stub match log"

    end

    context "when a request has been made configuring a stub" do

      include_context "registers a stub"

      before(:example) { register_stub }

      it "should not be recorded in the stub request log" do
        expect(response.body).to_not match(/#{request_uri}/)
      end

    end

    context "when a request has been made configuring a scenarios" do

      include_context "registers a stub"

      before(:example) { register_scenario }

      it "should not be recorded in the stub request log" do
        expect(response.body).to_not match(/#{request_uri}/)
      end

      def register_scenario
        stub_server.add_scenario_with_one_stub!("some_scenario", build_stub)
      end

    end

  end

end