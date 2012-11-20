require 'faraday'

class OAuth2Bearer < Faraday::Middleware
  def call(env)
    env[:request_headers]['Authorization'] = "Bearer #{@token}"
    @app.call env
  end
  def initialize(app, token = nil)
    super app
    @token = token
  end
end

Faraday.register_middleware :request, :oauth2bearer => lambda { OAuth2Bearer }
