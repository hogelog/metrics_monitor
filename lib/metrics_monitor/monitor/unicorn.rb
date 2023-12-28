module MetricsMonitor
  class Monitor
    class Unicorn
      class << self
        if defined?(::Unicorn)
          def worker_processes
            config = nil
            ObjectSpace.each_object(::Unicorn::Configurator) {|c| config = c }
            config.set[:worker_processes]
          end
        else
          def worker_processes
            nil
          end
        end
      end
    end
  end
end
