require "metrics_monitor"

MetricsMonitor.configure do |config|
  config.collectors << MetricsMonitor::Collector::GcStatCollector
  config.collectors << MetricsMonitor::Collector::ObjectStatCollector
end
