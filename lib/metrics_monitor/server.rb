require "json"
require "webrick"

module MetricsMonitor
  class Server
    def initialize
      @config = MetricsMonitor.config
      @collector = @config.collector
      @logger = @config.logger

      @running = false

      @server = WEBrick::HTTPServer.new({
        BindAddress: @config.bind,
        Port: @config.port,
        Logger: @logger,
        StartCallback: lambda { @running = true },
      })

      @server.mount_proc("/", self.method(:root))
      @server.mount_proc("/metrics", self.method(:metrics))
      @server.mount_proc("/metrics/meta", self.method(:metrics_meta))
    end

    def start
      @logger.info "Start MetricsMonitor::Agent #{@config.bind}:#{@config.port}"
      @server.start

      # Wait until start webrick
      until @running
      end
    end

    def shutdown
      @server.shutdown
    end

    def root(_req, res)
      response_text(res, "ok")
    end

    def metrics(_req, res)
      metrics = @collector.collect
      response_text(res, JSON.generate(metrics))
    end

    def metrics_meta(_req, res)
      meta = @collector.meta
      response_text(res, JSON.generate(meta))
    end

    private

    def response_text(res, text)
      res.header["Access-Control-Allow-Origin"] = "*"
      res.body = text
    end
  end
end
