require "logger"

require "metrics_monitor/version"

require "metrics_monitor/collector"
require "metrics_monitor/monitor"
require "metrics_monitor/server"
require "metrics_monitor/server_worker"

module MetricsMonitor
  class Error < StandardError; end
  class CollectorError < Error; end

  DEFAULT_BIND = "0.0.0.0"
  DEFAULT_PORT = 8686

  Config = Struct.new(:bind, :port, :collectors, :logger, :procs, :exclude_main_process, keyword_init: true)

  class << self
    def configure(start_server: true)
      @config = Config.new(bind: DEFAULT_BIND, port: DEFAULT_PORT, exclude_main_process: false)
      @config.collectors = [
        Collector::BasicCollector,
      ]
      yield(@config) if block_given?
      @logger = @config.logger || Logger.new(STDOUT, level: Logger::INFO)

      @monitor = Monitor.new(@config.collectors, procs: @config.procs)

      @server_worker = ServerWorker.new if start_server
    end

    def logger
      @logger
    end

    def config
      @config
    end

    def monitor
      @monitor
    end

    def server_worker
      @server_worker
    end
  end
end
