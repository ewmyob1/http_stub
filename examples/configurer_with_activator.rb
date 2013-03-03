module HttpStub
  module Examples

    class ConfigurerWithActivator
      include HttpStub::Configurer

      host "localhost"
      port 8001

      stub_activator "/an_activator", "/path1", method: :get, response: { status: 200, body: "Stub activator body" }
    end

  end
end
