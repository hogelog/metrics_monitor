module MetricsMonitor
  class Monitor
    class Unicorn
    end

    begin
      if defined?(::Unicorn)
        def Unicorn.worker_processes
          config = nil
          ObjectSpace.each_object(::Unicorn::Configurator) {|c| config = c }
          config.set[:worker_processes]
        end
      else
        def Unicorn.worker_processes
          nil
        end
      end
    end
  end
end
