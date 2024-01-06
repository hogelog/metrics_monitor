require_relative "../../lib/metrics_monitor"

MetricsMonitor::Collector::BasicCollector.configure do |options|
  options[:interval] = 10_000
end

MetricsMonitor::Collector::ObjectStatCollector.configure do |options|
  options[:interval] = 30_000
  options[:ignore_classes] = [BasicObject, Object, Module, Class]
  options[:memsize_threshold] = 5000
end

MetricsMonitor.configure do |config|
  config.collectors << MetricsMonitor::Collector::GcStatCollector
  config.collectors << MetricsMonitor::Collector::ObjectStatCollector
end

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
