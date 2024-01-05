require "cgi"
require "json"
require "webrick"

module MetricsMonitor
  class Server
    attr_reader :running

    def initialize
      @config = MetricsMonitor.config
      @monitor = MetricsMonitor.monitor

      @running = false

      @server = WEBrick::HTTPServer.new({
        BindAddress: @config.bind,
        Port: @config.port,
        Logger: MetricsMonitor.logger,
        StartCallback: lambda { @running = true },
        AccessLog: [],
        MaxClients: 10,
      })

      @server.mount("/", WEBrick::HTTPServlet::FileHandler, MetricsMonitor.visualizer_dir)
      @server.mount_proc("/healthcheck", self.method(:healthcheck))
      @server.mount_proc("/monitor", self.method(:monitor))
      @server.mount_proc("/meta", self.method(:meta))
    end

    def start
      MetricsMonitor.logger.info "Start MetricsMonitor::Server #{@config.bind}:#{@config.port}"
      @server.start
    end

    def shutdown
      @running = false
      @server.shutdown
    end

    def healthcheck(_req, res)
      response_text(res, "ok")
    end

    def monitor(req, res)
      options = parse_query(req)
      collector = req.path.sub(%r{^/monitor/}, "").to_sym
      metrics = @monitor.fetch_all_metrics(options.merge(collector:))
      response_json(res, metrics)
    end

    def meta(_req, res)
      meta_data = @monitor.fetch_meta_data
      response_json(res, meta_data)
    end

    private

    def response_text(res, text)
      res.header["access-control-allow-origin"] = "*"
      res.body = text
    end

    def response_json(res, data)
      res.header["content-type"] = "application/json"
      response_text(res, JSON.fast_generate(data))
    end

    def parse_query(req)
      return {} unless req.query_string
      query = CGI.parse(req.query_string)
      args = {}
      query.each do |key, val|
        args[key] = JSON.parse(val[0])
      end
      args
    end
  end
end
