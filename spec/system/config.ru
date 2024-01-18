require_relative "../../lib/metrics_monitor"

MetricsMonitor::Collector::BasicCollector.configure do |options|
  options[:interval] = 5_000
end

MetricsMonitor::Collector::ObjectStatCollector.configure do |options|
  options[:interval] = 5_000
  options[:target_classes] = [Hash, String, Array]
  options[:ignore_classes] = [BasicObject, Object, Module, Class]
  options[:memsize_threshold] = 5000
end

MetricsMonitor::Collector::ObjectTraceCollector.configure do |options|
  options[:enabled] = true
  options[:interval] = 10_000
  options[:target_classes] = [Hash, String, Array]
end

MetricsMonitor.configure do |config|
  config.collectors << MetricsMonitor::Collector::GcStatCollector
  config.collectors << MetricsMonitor::Collector::ObjectStatCollector
  config.collectors << MetricsMonitor::Collector::ObjectTraceCollector
  config.exclude_main_process = true
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
