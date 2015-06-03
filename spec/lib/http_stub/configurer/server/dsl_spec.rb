describe HttpStub::Configurer::Server::DSL do

  let(:server_facade) { instance_double(HttpStub::Configurer::Server::Facade) }

  let(:dsl) { HttpStub::Configurer::Server::DSL.new(server_facade) }

  it "produces stub builders" do
    expect(dsl).to be_a(HttpStub::Configurer::Request::StubBuilderProducer)
  end

  describe "#has_started!" do

    it "informs the facade that the server has started" do
      expect(server_facade).to receive(:server_has_started)

      dsl.has_started!
    end

  end

  describe "#add_stub!" do

    let(:stub)         { instance_double(HttpStub::Configurer::Request::Stub) }
    let(:stub_builder) { instance_double(HttpStub::Configurer::Request::StubBuilder, build: stub) }

    before(:example) { allow(server_facade).to receive(:stub_response) }

    shared_examples_for "adding a stub request" do

      it "builds the stub request" do
        expect(stub_builder).to receive(:build).and_return(stub)

        subject
      end

      it "informs the server facade of the stub request" do
        expect(server_facade).to receive(:stub_response).with(stub)

        subject
      end

    end

    context "when a stub builder is provided" do

      subject { dsl.add_stub!(stub_builder) }

      it_behaves_like "adding a stub request"

    end

    context "when a stub builder is not provided" do

      let(:block) { lambda { |_stub| "some block" } }

      before(:example) { allow(HttpStub::Configurer::Request::StubBuilder).to receive(:new).and_return(stub_builder) }

      subject { dsl.add_stub!(&block) }

      it "creates a stub builder" do
        expect(HttpStub::Configurer::Request::StubBuilder).to receive(:new)

        subject
      end

      it "yields the created builder to the provided block" do
        expect(block).to receive(:call).with(stub_builder)

        subject
      end

      it_behaves_like "adding a stub request"

    end

  end

  describe "#add_scenario!" do

    let(:activation_uri)   { "some/activation/uri" }
    let(:scenario)         { instance_double(HttpStub::Configurer::Request::Scenario) }
    let(:scenario_builder) { instance_double(HttpStub::Configurer::Request::ScenarioBuilder, build: scenario) }

    before(:example) { allow(server_facade).to receive(:define_scenario) }

    let(:block) { lambda { |_scenario| "some block" } }

    before(:example) do
      allow(HttpStub::Configurer::Request::ScenarioBuilder).to receive(:new).and_return(scenario_builder)
    end

    subject { dsl.add_scenario!(activation_uri, &block) }

    context "when response defaults have been established" do

      let(:response_defaults) { { key: "value" } }

      before(:example) { dsl.response_defaults = { key: "value" } }

      it "creates a scenario builder containing the response defaults" do
        expect(HttpStub::Configurer::Request::ScenarioBuilder).to receive(:new).with(response_defaults, anything)

        subject
      end

      it "creates a scenario builder containing the provided activation uri" do
        expect(HttpStub::Configurer::Request::ScenarioBuilder).to receive(:new).with(anything, activation_uri)

        subject
      end

    end

    context "when no response defaults have been established" do

      it "creates a scenario builder with empty response defaults" do
        expect(HttpStub::Configurer::Request::ScenarioBuilder).to receive(:new).with({}, anything)

        subject
      end

    end

    it "yields the created builder to the provided block" do
      expect(block).to receive(:call).with(scenario_builder)

      subject
    end

    it "builds the scenario request" do
      expect(scenario_builder).to receive(:build).and_return(scenario)

      subject
    end

    it "informs the server facade to submit the scenario request" do
      expect(server_facade).to receive(:define_scenario).with(scenario)

      subject
    end

  end

  describe "#add_activator!" do

    let(:scenario) { instance_double(HttpStub::Configurer::Request::Scenario) }
    let(:stub_activator_builder) do
      instance_double(HttpStub::Configurer::Request::StubActivatorBuilder, build: scenario)
    end

    before(:example) { allow(server_facade).to receive(:define_scenario) }

    let(:block) { lambda { |_activator| "some block" } }

    before(:example) do
      allow(HttpStub::Configurer::Request::StubActivatorBuilder).to receive(:new).and_return(stub_activator_builder)
    end

    subject { dsl.add_activator!(&block) }

    context "when response defaults have been established" do

      let(:response_defaults) { { key: "value" } }

      before(:example) { dsl.response_defaults = { key: "value" } }

      it "creates a stub activator builder containing the response defaults" do
        expect(HttpStub::Configurer::Request::StubActivatorBuilder).to receive(:new).with(response_defaults)

        subject
      end

    end

    context "when no response defaults have been established" do

      it "creates a stub activator builder with empty response defaults" do
        expect(HttpStub::Configurer::Request::StubActivatorBuilder).to receive(:new).with({})

        subject
      end

    end

    it "yields the created builder to the provided block" do
      expect(block).to receive(:call).with(stub_activator_builder)

      subject
    end

    it "builds a scenario request" do
      expect(stub_activator_builder).to receive(:build).and_return(scenario)

      subject
    end

    it "informs the server facade to submit the scenario request" do
      expect(server_facade).to receive(:define_scenario).with(scenario)

      subject
    end

  end

  describe "#activate!" do

    let(:uri) { "/some/activation/uri" }

    it "delegates to the server facade" do
      expect(server_facade).to receive(:activate).with(uri)

      dsl.activate!(uri)
    end

  end

  describe "#remember_stubs" do

    it "delegates to the server facade" do
      expect(server_facade).to receive(:remember_stubs)

      dsl.remember_stubs
    end

  end

  describe "#recall_stubs!" do

    it "delegates to the server facade" do
      expect(server_facade).to receive(:recall_stubs)

      dsl.recall_stubs!
    end

  end

  describe "#clear_stubs!" do

    it "delegates to the server facade" do
      expect(server_facade).to receive(:clear_stubs)

      dsl.clear_stubs!
    end

  end

  describe "#clear_scenarios!" do

    it "delegates to the server facade" do
      expect(server_facade).to receive(:clear_scenarios)

      dsl.clear_scenarios!
    end

  end

end
