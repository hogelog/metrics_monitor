module MetricsMonitor
  class Agent
    def initialize
      @server = Server.new

      @thread = Thread.new do
        @server.start
      end

      at_exit do
        stop
      end
    end

    def stop
      @server.shutdown
      if @thread.alive?
        @thread.wakeup
        @thread.join
      end
    end
  end
end
