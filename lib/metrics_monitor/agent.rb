require "json"
require "webrick"

module MetricsMonitor
  class Agent

    HEADER_ALLOW_ORIGIN = "Access-Control-Allow-Origin"

    def initialize
      @config = MetricsMonitor.config
      @collector = @config.collector

      @logger = @config.logger

      @server = WEBrick::HTTPServer.new({
          BindAddress: @config.bind,
          Port: @config.port,
      })
      @server.mount_proc("/") do |req, res|
        response_text(res, "ok")
      end
      @server.mount_proc("/metrics") do |req, res|
        metrics = @collector.collect
        response_text(res, JSON.generate(metrics))
      end
      @server.mount_proc("/metrics/meta") do |req, res|
        meta = @collector.meta
        response_text(res, JSON.generate(meta))
      end

      @thread = Thread.new do
        @logger.info "Start MetricsMonitor::Agent #{@config.bind}:#{@config.port}"
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

    private

    def response_text(res, text)
      res.header["Access-Control-Allow-Origin"] = "*"
      res.body = text
    end
  end
end
