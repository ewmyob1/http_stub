describe HttpStub::Server::Stub::Registry do

  let(:registry)      { instance_double(HttpStub::Server::Registry) }

  let(:stub_registry) { HttpStub::Server::Stub::Registry.new }

  before(:example) { allow(HttpStub::Server::Registry).to receive(:new).and_return(registry) }

  describe "#add" do

    let(:stub)    { instance_double(HttpStub::Server::Stub::Instance) }
    let(:request) { instance_double(Rack::Request) }

    it "delegates to an underlying simple registry" do
      expect(registry).to receive(:add).with(stub, request)

      stub_registry.add(stub, request)
    end

  end

  describe "#concat" do

    let(:stubs)   { (1..3).map { instance_double(HttpStub::Server::Stub::Instance) } }
    let(:request) { instance_double(Rack::Request) }

    it "delegates to an underlying simple registry" do
      expect(registry).to receive(:concat).with(stubs, request)

      stub_registry.concat(stubs, request)
    end

  end

  describe "#find_for" do

    let(:request) { instance_double(Rack::Request) }

    subject { stub_registry.find_for(request) }

    it "delegates to an underlying simple registry to find based on the request" do
      expect(registry).to receive(:find).with(criteria: request, request: request)

      subject
    end

    context "when a stub is found" do

      let(:triggers) { instance_double(HttpStub::Server::Stub::Triggers) }
      let(:stub)     { instance_double(HttpStub::Server::Stub::Instance, triggers: triggers) }

      before(:example) { allow(registry).to receive(:find).and_return(stub) }

      it "should add the stubs triggers to the registry" do
        expect(triggers).to receive(:add_to).with(stub_registry, request)

        subject
      end

      it "returns the stub found in the underlying registry" do
        allow(triggers).to receive(:add_to)

        expect(subject).to eql(stub)
      end

    end

    context "when a stub is not found" do

      before(:example) { allow(registry).to receive(:find).and_return(nil) }

      it "returns the result from the underlying registry" do
        expect(subject).to eql(nil)
      end

    end

  end

  describe "#recall" do

    subject { stub_registry.recall }

    context "when the state of the registry has been remembered" do

      let(:last_stub_remembered) { instance_double(HttpStub::Server::Stub::Instance) }

      before(:example) do
        allow(registry).to receive(:last).and_return(last_stub_remembered)
        stub_registry.remember
      end

      it "causes the underlying registry to rollback to the last stub added before the state was remembered" do
        expect(registry).to receive(:rollback_to).with(last_stub_remembered)

        subject
      end

    end

    context "when the state of the registry has not been remembered" do

      it "does not rollback the underlying registry" do
        expect(registry).to_not receive(:rollback_to)

        subject
      end

    end

  end

  describe "#all" do

    let(:stubs) { (1..3).map { instance_double(HttpStub::Server::Stub::Instance) } }

    subject { stub_registry.all }

    it "delegates to an underlying simple registry" do
      expect(registry).to receive(:all)

      subject
    end

    it "returns the result from the underlying registry" do
      allow(registry).to receive(:all).and_return(stubs)

      expect(subject).to eql(stubs)
    end

  end

  describe "#clear" do

    let(:request) { instance_double(Rack::Request) }

    it "delegates to an underlying simple registry" do
      expect(registry).to receive(:clear).with(request)

      stub_registry.clear(request)
    end

  end

end
