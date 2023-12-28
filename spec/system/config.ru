require_relative "../../lib/metrics_monitor/setup"

class RackApp
  def initialize
    @array = []
  end

  def call(env)
    path = env["PATH_INFO"]
    if path == "/leak"
      10000.times{ @array << rand }
    end

    [200, { 'content-type' => 'text/plain' }, ["hello"]]
  end
end

run RackApp.new
