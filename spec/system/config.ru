require_relative "../../lib/metrics_monitor"

MetricsMonitor.configure do |config|
  MetricsMonitor::Collector::Memprof2Collector.configure do |options|
    options[:trace] = /config\.ru/
  end

  config.collectors << MetricsMonitor::Collector::GcStatCollector
  config.collectors << MetricsMonitor::Collector::Memprof2Collector

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

    [200, { 'Content-Type' => 'text/plain' }, ["hello"]]
  end
end

run RackApp.new
