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
      args = parse_query(req)
      data = @monitor.fetch_all_data(args)
      response_text(res, JSON.generate(data))
    end

    def monitor_meta(_req, res)
      meta_data = @monitor.fetch_meta_data
      response_text(res, JSON.generate(meta_data))
    end

    private

    def response_text(res, text)
      res.header["Access-Control-Allow-Origin"] = "*"
      res.body = text
    end

    def parse_query(req)
      return {} unless req.query_string
      query = CGI.parse(req.query_string)
      args = {}
      query.each do |key, val|
        args[key] = val[0]
      end
      args
    end
  end
end
