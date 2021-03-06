describe HttpStub::Configurer::Request::StubResponse do

  let(:stub_fixture) { HttpStub::StubFixture.new }
  let(:fixture)      { stub_fixture.response }

  let(:stub_response) { HttpStub::Configurer::Request::StubResponse.new(stub_fixture.id, fixture.symbolized) }

  describe "#payload" do

    subject { stub_response.payload }

    context "when a status response argument is provided" do

      it "has a response entry for the argument" do
        expect(subject).to include(status: fixture.status)
      end

    end

    context "when no status response argument is provided" do

      before(:example) { fixture.status = nil }

      it "has a response entry with an empty status code" do
        expect(subject).to include(status: "")
      end

    end

    context "when response headers are provided" do

      it "has a headers response entry containing the the provided headers" do
        expect(subject).to include(headers: fixture.headers)
      end

    end

    context "when response headers are omitted" do

      before(:example) { fixture.headers = nil }

      it "has a headers response entry containing an empty hash" do
        expect(subject).to include(headers: {})
      end

    end

    context "when a response body argument is provided" do

      before(:example) do
        fixture.body = "some body"
        fixture.json = nil
      end

      it "has a response body entry that contains the body argument" do
        expect(subject).to include(body: fixture.body)
      end

    end

    context "when a response json argument is provided" do

      let(:json_object) { { some_key: "some value" } }

      before(:example) do
        fixture.body = nil
        fixture.json = json_object
      end

      it "has a response body entry that contains the json argument converted to JSON" do
        expect(subject).to include(body: json_object.to_json)
      end

    end

    context "when a delay option is provided" do

      it "has a response entry for the argument" do
        expect(subject).to include(delay_in_seconds: fixture.delay_in_seconds)
      end

    end

    context "when a delay option is omitted" do

      before(:example) { fixture.delay_in_seconds = nil }

      it "has a response entry with an empty delay" do
        expect(subject).to include(delay_in_seconds: "")
      end

    end

  end

  describe "#file" do

    subject { stub_response.file }

    context "when the body contains a file hash" do

      let(:content_type_key)   { "content-type" }
      let(:content_type_value) { "some-content-type" }
      let(:file_path)          { "some/file/path" }
      let(:file_name)          { "some_file.name" }

      before(:example) do
        fixture.headers = { content_type_key => content_type_value }
        fixture.body    = { file: { path: file_path, name: file_name } }
      end

      it "creates a response file containing the stub id" do
        expect_response_file_to_be_created_with(id: stub_fixture.id)

        subject
      end

      it "creates a response file containing the provided file path" do
        expect_response_file_to_be_created_with(path: file_path)

        subject
      end

      it "creates a response file containing the provided file name" do
        expect_response_file_to_be_created_with(name: file_name)

        subject
      end

      context "when the content type header key is provided" do

        context "in lower case" do

          let(:content_type_key) { "content-type" }

          it "creates a response file whose type is the content-type response header" do
            expect_response_file_to_be_created_with(type: content_type_value)

            subject
          end

        end

        context "in upper case" do

          let(:content_type_key) { "Content-Type" }

          it "creates a response file whose type is the content-type response header" do
            expect_response_file_to_be_created_with(type: content_type_value)

            subject
          end

        end

      end

      context "when the content type header is not provided" do

        let(:content_type_value) { nil }

        it "creates a response file whose type is nil, which allows the server to default the value" do
          expect_response_file_to_be_created_with(type: nil)

          subject
        end

      end

      it "returns the created response file" do
        response_file = instance_double(HttpStub::Configurer::Request::StubResponseFile)
        allow(HttpStub::Configurer::Request::StubResponseFile).to receive(:new).and_return(response_file)

        expect(subject).to eql(response_file)
      end

      def expect_response_file_to_be_created_with(hash)
        expect(HttpStub::Configurer::Request::StubResponseFile).to receive(:new).with(hash_including(hash))
      end

    end

    context "when the body contains text" do

      before(:example) { fixture.body = "some text" }

      it "returns nil" do
        expect(subject).to be(nil)
      end

    end

  end

end
