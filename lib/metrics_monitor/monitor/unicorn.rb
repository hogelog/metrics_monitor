module MetricsMonitor
  class Monitor
    class Unicorn
      class << self
        def config
          if defined?(::Unicorn)
            return @config if @config
            @config = ObjectSpace.each_object(::Unicorn::Configurator).first
          end
        end

        def worker_processes
          config&.then{|c| c.set[:worker_processes] }
        end
      end
    end
  end
end
