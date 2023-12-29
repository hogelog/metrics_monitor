require "metrics_monitor"

module MetricsMonitor
  class << self
    def setup
      configure do |config|
        config.collectors << MetricsMonitor::Collector::GcStatCollector
        config.collectors << MetricsMonitor::Collector::ObjectStatCollector
      end
    end
  end

  if defined?(Rails)
    class Railtie < Rails::Railtie
      initializer "metrics_monitor" do |_app|
        MetricsMonitor.setup
      end
    end
  end
end

unless defined?(Rails)
  MetricsMonitor.setup
end
