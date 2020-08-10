require "json"
require "webrick"

module MetricsMonitor
  class Agent
    def initialize
      @config = MetricsMonitor.config
      @collector = @config.collector

      @logger = Rails.logger

      @server = WEBrick::HTTPServer.new({
          BindAddress: @config.host,
          Port: @config.port,
      })
      @server.mount_proc("/") do |req, res|
        res.body = "ok"
      end
      @server.mount_proc("/metrics") do |req, res|
        metrics = @collector.collect
        res.body = JSON.generate(metrics)
      end

      @thread = Thread.new do
        @logger.info "Start MetricsMonitor::Agent #{@config.host}:#{@config.port}"
        @server.start
      end

      at_exit do
        @server.shutdown
        if @thread.alive?
          @thread.wakeup
          @thread.join
        end
      end
    end
  end
end
