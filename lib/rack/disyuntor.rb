require "rack"
require_relative "../disyuntor"

class Rack::Disyuntor
  def initialize(app, options={})
    @app = app

    options[:on_fail] ||= -> { circuit_open_response }

    @circuit_breaker = Disyuntor.new(options)
  end

  def call(env)
    @circuit_breaker.try { @app.call(env) }
  end

  def circuit_open_response
    [503, { "Content-Type" => "text/plain" }, ["Service Unavailable"]]
  end
end
