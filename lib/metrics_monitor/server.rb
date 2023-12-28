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
      })

      @server.mount_proc("/", self.method(:root))
      @server.mount_proc("/monitor", self.method(:monitor))
      @server.mount_proc("/monitor/meta", self.method(:monitor_meta))
    end

    def start
      MetricsMonitor.logger.info "Start MetricsMonitor::Server #{@config.bind}:#{@config.port}"
      @server.start
    end

    def shutdown
      @running = false
      @server.shutdown
    end

    def root(_req, res)
      response_text(res, "ok")
    end

    def monitor(req, res)
      options = parse_query(req)
      data = @monitor.fetch_all_data(options)
      response_json(res, data)
    end

    def monitor_meta(_req, res)
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
