describe HttpStub::Configurer::DSL::StubBuilder do

  let(:default_builder) { nil }

  let(:builder) { HttpStub::Configurer::DSL::StubBuilder.new(default_builder) }

  shared_context "triggers one scenario" do

    let(:trigger_scenario) { "Some triggered scenario" }

    before(:example) { builder.trigger(scenario: trigger_scenario) }

  end

  shared_context "triggers many scenarios" do

    let(:trigger_scenarios) { (1..3).map { |i| "Some triggered scenario #{i}" } }

    before(:example) { builder.trigger(scenarios: trigger_scenarios) }

  end

  shared_context "triggers one stub" do

    let(:trigger_stub)         { instance_double(HttpStub::Configurer::Request::Stub) }
    let(:trigger_stub_builder) { instance_double(described_class, build: trigger_stub) }

    before(:example) { builder.trigger(stub: trigger_stub_builder) }

  end

  shared_context "triggers many stubs" do

    let(:trigger_stubs)         { (1..3).map { instance_double(HttpStub::Configurer::Request::Stub) } }
    let(:trigger_stub_builders) do
      trigger_stubs.map { |stub| instance_double(described_class, build: stub) }
    end

    before(:example) { builder.trigger(stubs: trigger_stub_builders) }

  end

  describe "constructor" do

    class HttpStub::Configurer::DSL::StubBuilderWithObservedMerge < HttpStub::Configurer::DSL::StubBuilder

      attr_reader :merged_stub_builders

      def initialize(parent_builder=nil, &block)
        @merged_stub_builders = []
        super(parent_builder, &block)
      end

      def merge!(stub_builder)
        @merged_stub_builders << stub_builder
      end

    end

    context "when a parent builder is provided" do

      let(:parent_builder) { instance_double(described_class) }

      let(:builder) { HttpStub::Configurer::DSL::StubBuilderWithObservedMerge.new(parent_builder) }

      it "merges the parent builder" do
        builder

        expect(builder.merged_stub_builders).to eql([ parent_builder ])
      end

    end

    context "when a block is provided" do

      let(:block_verifier) { double("BlockVerifier", verify: nil) }
      let(:block)          { lambda { |builder| block_verifier.verify(builder) } }

      let(:builder) { HttpStub::Configurer::DSL::StubBuilderWithObservedMerge.new(&block) }

      it "creates a builder that is yielded to the provided block" do
        expect(block_verifier).to receive(:verify).with(a_kind_of(described_class))

        builder
      end

      it "does not merge any parent builders" do
        builder

        expect(builder.merged_stub_builders).to eql([])
      end

    end

    context "when neither a parent builder or block is provided" do

      let(:builder) { HttpStub::Configurer::DSL::StubBuilderWithObservedMerge.new(nil) }

      it "does not merge any parent builder" do
        builder

        expect(builder.merged_stub_builders).to eql([])
      end

    end

  end


  describe "#match_requests" do

    let(:fixture) { HttpStub::StubFixture.new }

    subject { builder.match_requests(fixture.request.symbolized) }

    it "returns the builder to support method chaining" do
      expect(subject).to eql(builder)
    end

  end

  describe "#schema" do

    let(:type) { :some_type }

    subject { builder.schema(type, schema_definition) }

    context "when a definition is provided in a ruby hash" do

      let(:schema_definition) { { schema: "definition" } }

      it "returns a hash with a :schema entry containing both the type and schema definition" do
        expect(subject).to eql(schema: { type: type, definition: schema_definition })
      end

    end

  end

  describe "#respond_with" do

    context "when a block is provided referencing the matching request" do

      let(:request_referencer) { instance_double(HttpStub::Configurer::DSL::RequestReferencer) }

      subject { builder.respond_with { |request| { headers: request.headers[:some_header] } } }

      it "includes the hash returned from the evaluated block in the response hash" do
        subject

        expect(builder.response).to include(headers: a_string_matching(/^control/))
      end

      it "returns the builder to support method chaining" do
        expect(subject).to eql(builder)
      end

    end

    context "when a block is not provided" do

      subject { builder.respond_with(status: 201) }

      it "includes the proivded hash in the response hash" do
        subject

        expect(builder.response).to include(status: 201)
      end

      it "returns the builder to support method chaining" do
        expect(subject).to eql(builder)
      end

    end

  end

  describe "#trigger" do

    let(:args) { {} }

    subject { builder.trigger(args) }

    it "returns the builder to support method chaining" do
      expect(subject).to eql(builder)
    end

    context "when scenarios are provided" do

      let(:scenarios) { (1..3).map { |i| "Scenario name #{i}" } }

      let(:args) { { scenarios: scenarios } }

      it "adds the scenarios" do
        subject

        expect(builder.triggers).to include(scenarios: scenarios)
      end

    end

    context "when a scenario is provided" do

      let(:scenario) { "Some scenario name" }

      let(:args) { { scenario: scenario } }

      it "adds the scenario" do
        subject

        expect(builder.triggers).to include(scenarios: [ scenario ])
      end

    end

    context "when stubs are provided" do

      let(:stubs) { (1..3).map { instance_double(described_class) } }

      let(:args) { { stubs: stubs } }

      it "adds the stubs" do
        subject

        expect(builder.triggers).to include(stubs: stubs)
      end

    end

    context "when a stub is provided" do

      let(:stub) { instance_double(described_class) }

      let(:args) { { stub: stub } }

      it "adds the stub" do
        subject

        expect(builder.triggers).to include(stubs: [ stub ])
      end

    end

  end

  describe "#invoke" do

    context "when the block accepts an argument" do

      subject { builder.invoke { |builder| builder.match_requests(uri: "/some_uri") } }

      it "invokes the block with the builder as the argument" do
        expect(builder).to receive(:match_requests).with(uri: "/some_uri")

        subject
      end

    end

    context "when the block accepts no arguments" do

      subject { builder.invoke { match_requests(uri: "/some_uri") } }

      it "invokes the block in the context of the builder" do
        expect(builder).to receive(:match_requests).with(uri: "/some_uri")

        subject
      end

    end

  end

  describe "#merge!" do

    subject { builder.merge!(provided_builder) }

    shared_context "a completely configured provided builder" do

      let(:provided_trigger_scenarios)     { (1..3).map { |i| "Triggered scenario #{i}" } }
      let(:provided_trigger_stub_builders) { (1..3).map { instance_double(described_class) } }

      let(:provided_builder) do
        described_class.new.tap do |builder|
          builder.match_requests(uri: "/replacement_uri", method: :put,
                                 headers:    { request_header_key: "replacement request header value",
                                               other_request_header_key: "other request header value" },
                                 parameters: { parameter_key: "replacement parameter value",
                                               other_request_parameter_key: "other request parameter value" })
          builder.respond_with(status: 203,
                               headers: { response_header_key: "reaplcement response header value",
                                          other_response_header_key: "other response header value" },
                               body: "replacement body value",
                               delay_in_seconds: 3)
          builder.trigger(scenarios: provided_trigger_scenarios,
                          stubs:     provided_trigger_stub_builders)
        end
      end

    end

    context "when the builder has been completely configured" do

      let(:original_trigger_scenarios)     { (1..3).map { |i| "Original trigger scenario #{i}" } }
      let(:original_trigger_stub_builders) { (1..3).map { instance_double(described_class) } }

      before(:example) do
        builder.match_requests(uri: "/original_uri", method: :get,
                               headers:    { request_header_key: "original request header value" },
                               parameters: { parameter_key: "original parameter value" })
        builder.respond_with(status: 202,
                             headers: { response_header_key: "original response header value" },
                             body: "original body",
                             delay_in_seconds: 2)
        builder.trigger(scenarios: original_trigger_scenarios,
                        stubs:     original_trigger_stub_builders)
      end

      context "and a builder that is completely configured is provided" do
        include_context "a completely configured provided builder"

        it "replaces the uri" do
          subject

          expect(builder.request).to include(uri: "/replacement_uri")
        end

        it "replaces the request method" do
          subject

          expect(builder.request).to include(method: :put)
        end

        it "deeply merges the request headers" do
          subject

          expect(builder.request).to include(headers: { request_header_key: "replacement request header value",
                                                        other_request_header_key: "other request header value" })
        end

        it "deeply merges the request parameters" do
          subject

          expect(builder.request).to(
            include(parameters: { parameter_key: "replacement parameter value",
                                  other_request_parameter_key: "other request parameter value" })
          )
        end

        it "replaces the response status" do
          subject

          expect(builder.response).to include(status: 203)
        end

        it "deeply merges the response headers" do
          subject

          expect(builder.response).to include(headers: { response_header_key: "reaplcement response header value",
                                                         other_response_header_key: "other response header value" })
        end

        it "replaces the body" do
          subject

          expect(builder.response).to include(body: "replacement body value")
        end

        it "replaces the response delay" do
          subject

          expect(builder.response).to include(delay_in_seconds: 3)
        end

        it "adds to the triggered scenarios" do
          subject

          expect(builder.triggers).to include(scenarios: original_trigger_scenarios + provided_trigger_scenarios)
        end

        it "adds to the triggered stubs" do
          subject

          expect(builder.triggers).to include(stubs: original_trigger_stub_builders + provided_trigger_stub_builders)
        end

      end

      context "and a builder that is empty is provided" do

        let(:provided_builder) { described_class.new }

        it "preserves the uri" do
          subject

          expect(builder.request).to include(uri: "/original_uri")
        end

        it "preserves the request method" do
          subject

          expect(builder.request).to include(method: :get)
        end

        it "preserves the request headers" do
          subject

          expect(builder.request).to include(headers: { request_header_key: "original request header value" })
        end

        it "preserves the request parameters" do
          subject

          expect(builder.request).to include(parameters: { parameter_key: "original parameter value" })
        end

        it "preserves the response status" do
          subject

          expect(builder.response).to include(status: 202)
        end

        it "preserves the response headers" do
          subject

          expect(builder.response).to include(headers: { response_header_key: "original response header value" })
        end

        it "preserves the body" do
          subject

          expect(builder.response).to include(body: "original body")
        end

        it "preserves the response delay" do
          subject

          expect(builder.response).to include(delay_in_seconds: 2)
        end

        it "preserves the triggered scenarios" do
          subject

          expect(builder.triggers).to include(scenarios: original_trigger_scenarios)
        end

        it "preserves the triggered stubs" do
          subject

          expect(builder.triggers).to include(stubs: original_trigger_stub_builders)
        end

      end

    end

    context "when the builder has not been previously configured" do
      include_context "a completely configured provided builder"

      it "assumes the provided uri" do
        subject

        expect(builder.request).to include(uri: "/replacement_uri")
      end

      it "assumes the provided request method" do
        subject

        expect(builder.request).to include(method: :put)
      end

      it "assumes the provided request headers" do
        subject

        expect(builder.request).to include(headers: { request_header_key: "replacement request header value",
                                                      other_request_header_key: "other request header value" })
      end

      it "assumes the provided request parameters" do
        subject

        expect(builder.request).to(
          include(parameters: { parameter_key: "replacement parameter value",
                                other_request_parameter_key: "other request parameter value" })
        )
      end

      it "assumes the provided response status" do
        subject

        expect(builder.response).to include(status: 203)
      end

      it "assumes the provided response headers" do
        subject

        expect(builder.response).to include(headers: { response_header_key: "reaplcement response header value",
                                                       other_response_header_key: "other response header value" })
      end

      it "assumes the provided response body" do
        subject

        expect(builder.response).to include(body: "replacement body value")
      end

      it "assumes the provided response delay" do
        subject

        expect(builder.response).to include(delay_in_seconds: 3)
      end

      it "assumes the provided triggered scenarios" do
        subject

        expect(builder.triggers).to include(scenarios: provided_trigger_scenarios)
      end

      it "assumes the provided triggered stubs" do
        subject

        expect(builder.triggers).to include(stubs: provided_trigger_stub_builders)
      end

    end

  end

  describe "#build" do

    let(:fixture)  { HttpStub::StubFixture.new }
    let(:triggers) { { scenarios: [], stubs: [] } }
    let(:stub)     { instance_double(HttpStub::Configurer::Request::Stub) }

    subject do
      builder.match_requests(fixture.request.symbolized)
      builder.respond_with(fixture.response.symbolized)
      builder.trigger(triggers)

      builder.build
    end

    before(:example) { allow(HttpStub::Configurer::Request::Stub).to receive(:new).and_return(stub) }

    context "when provided a request match and response data" do

      it "creates a stub payload with request options that include the uri and the provided request options" do
        expect_stub_to_be_created_with(request: fixture.request.symbolized)

        subject
      end

      it "creates a stub payload with response arguments" do
        expect_stub_to_be_created_with(response: fixture.response.symbolized)

        subject
      end

      describe "creates a stub payload with triggers that" do

        context "when a scenario trigger is added" do
          include_context "triggers one scenario"

          it "contains the provided trigger scenario name" do
            expect_stub_to_be_created_with_triggers(scenario_names: [ trigger_scenario ])

            subject
          end

        end

        context "when many scenario triggers are added" do
          include_context "triggers many scenarios"

          it "contains the provided trigger scenario names" do
            expect_stub_to_be_created_with_triggers(scenario_names: trigger_scenarios)

            subject
          end

        end

        context "when a stub trigger is added" do
          include_context "triggers one stub"

          it "contains the provided trigger builder" do
            expect_stub_to_be_created_with_triggers(stubs: [ trigger_stub ])

            subject
          end

        end

        context "when many stub triggers are added" do
          include_context "triggers many stubs"

          it "contains the provided trigger builders" do
            expect_stub_to_be_created_with_triggers(stubs: trigger_stubs)

            subject
          end

        end

      end

      context "when a default stub builder is provided that contains defaults" do

        let(:request_defaults) do
          {
            uri:        "/uri/value",
            headers:    { "request_header_name_1" => "request header value 1",
                          "request_header_name_2" => "request header value 2" },
            parameters: { "parameter_name_1" => "parameter value 1",
                          "parameter_name_2" => "parameter value 2" },
            body:       "body value"
          }
        end
        let(:response_defaults) do
          {
            status:           203,
            headers:          { "response_header_name_1" => "response header value 1",
                                "response_header_name_2" => "response header value 2" },
            body:             "some body",
            delay_in_seconds: 8
          }
        end
        let(:trigger_scenario_defaults)      { (1..3).map { |i| "Default trigger scenario #{i}" } }
        let(:trigger_stub_defaults)          { (1..3).map { instance_double(HttpStub::Configurer::Request::Stub) } }
        let(:trigger_stub_builder_defaults)  do
          trigger_stub_defaults.map { |stub| instance_double(described_class, build: stub) }
        end

        let(:default_builder) do
          instance_double(described_class, request:  request_defaults,
                                           response: response_defaults,
                                           triggers: { scenarios: trigger_scenario_defaults,
                                                       stubs:     trigger_stub_builder_defaults })
        end

        describe "the built request payload" do

          let(:request_overrides) do
            {
              uri:        "/some/updated/uri",
              headers:    { "request_header_name_2" => "updated request header value 2",
                            "request_header_name_3" => "request header value 3" },
              parameters: { "parameter_name_2" => "updated parameter value 2",
                            "parameter_name_3" => "parameter value 3" },
              body:       "updated body value"
            }
          end

          before(:example) { fixture.request = request_overrides }

          it "overrides any defaults with values established in the stub" do
            expect_stub_to_be_created_with(
              request: {
                uri:              "/some/updated/uri",
                headers:          { "request_header_name_1" => "request header value 1",
                                    "request_header_name_2" => "updated request header value 2",
                                    "request_header_name_3" => "request header value 3" },
                parameters:       { "parameter_name_1" => "parameter value 1",
                                    "parameter_name_2" => "updated parameter value 2",
                                    "parameter_name_3" => "parameter value 3" },
                body:             "updated body value"
              }
            )

            subject
          end

        end

        describe "the built response payload" do

          let(:response_overrides) do
            {
              status:  302,
              headers: { "response_header_name_2" => "updated response header value 2",
                         "response_header_name_3" => "response header value 3" },
              body:    "updated body"
            }
          end

          before(:example) { fixture.response = response_overrides }

          it "overrides any defaults with values established in the stub" do
            expect_stub_to_be_created_with(
              response: {
                status:           302,
                headers:          { "response_header_name_1" => "response header value 1",
                                    "response_header_name_2" => "updated response header value 2",
                                    "response_header_name_3" => "response header value 3" },
                body:             "updated body",
                delay_in_seconds: 8
              }
            )

            subject
          end

        end

        describe "the built triggers payload" do

          let(:trigger_scenarios)     { (1..3).map { |i| "Trigger scenario #{i}" } }
          let(:trigger_stubs)         { (1..3).map { instance_double(HttpStub::Configurer::Request::Stub) } }
          let(:trigger_stub_builders) do
            trigger_stubs.map { |stub| instance_double(described_class, build: stub) }
          end

          let(:triggers) { { scenarios: trigger_scenarios, stubs: trigger_stub_builders } }

          it "combines any scenario defaults with values established in the stub" do
            expect_stub_to_be_created_with_triggers(scenario_names: trigger_scenario_defaults + trigger_scenarios)

            subject
          end

          it "combines any stub defaults with values established in the stub" do
            expect_stub_to_be_created_with_triggers(stubs: trigger_stub_defaults + trigger_stubs)

            subject
          end

        end

      end

      it "returns the created stub" do
        expect(subject).to eql(stub)
      end

    end

    def expect_stub_to_be_created_with(args)
      expect(HttpStub::Configurer::Request::Stub).to receive(:new).with(hash_including(args))
    end

    def expect_stub_to_be_created_with_triggers(args)
      expect_stub_to_be_created_with(triggers: hash_including(args))
    end

  end

end
