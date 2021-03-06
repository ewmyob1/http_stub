module HttpStub
  module Server
    module Request

      class SinatraRequest

        attr_reader :base_uri, :uri, :method, :headers, :parameters, :body

        def initialize(rack_request, sinatra_parameters)
          @base_uri   = rack_request.base_url
          @uri        = rack_request.path_info
          @method     = rack_request.request_method.downcase
          @headers    = HttpStub::Server::Request::Headers.create(rack_request)
          @parameters = HttpStub::Server::Request::Parameters.create(sinatra_parameters)
          @body       = rack_request.body.read.tap { rack_request.body.rewind }
        end

        def to_json(*args)
          { uri: @uri, method: @method, headers: @headers, parameters: @parameters, body: @body }.to_json(*args)
        end

      end

    end
  end
end
