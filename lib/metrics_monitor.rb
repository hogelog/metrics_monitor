require "logger"

require "metrics_monitor/version"

require "metrics_monitor/collector_base"
require "metrics_monitor/basic_collector"

require "metrics_monitor/agent"
require "metrics_monitor/server"

module MetricsMonitor
  class Error < StandardError; end
  class CollectorError < Error; end

  DEFAULT_BIND = "0.0.0.0"
  DEFAULT_PORT = 8686

  Config = Struct.new(:bind, :port, :collector, :logger, keyword_init: true)

  class << self
    def configure(start_agent: true)
      MetricsMonitor.config = Config.new(bind: DEFAULT_BIND, port: DEFAULT_PORT)
      yield(MetricsMonitor.config) if block_given?
      MetricsMonitor.config.collector ||= BasicCollector.new
      MetricsMonitor.config.logger ||= Logger.new(STDOUT, level: Logger::INFO)

      MetricsMonitor.agent = MetricsMonitor::Agent.new if start_agent
    end

    def agent=(agent)
      @agent = agent
    end

    def agent
      @agent
    end

    def config=(config)
      @config = config
    end

    def config
      @config
    end
  end
end
