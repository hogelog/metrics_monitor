require "metrics_monitor/monitor/unicorn"

require "timeout"

module MetricsMonitor
  class Monitor
    def self.worker_processes
      return MetricsMonitor::Monitor::Unicorn.worker_processes if MetricsMonitor::Monitor::Unicorn.config
    end

    def initialize(collector_classes, procs: nil)
      @parent_pid = Process.pid

      @collectors = {}
      collector_classes.each do |klass|
        collector = klass.new
        @collectors[collector.key] = collector
      end

      @result_reader, @result_writer = IO.pipe

      @procs = procs || self.class.worker_processes

      @dispatcher = Dispatcher.new(@procs.to_i) if @procs
    end

    def fetch_meta_data
      meta_data = {}
      @collectors.each do |key, collector|
        meta_data[key] = collector.fetch_meta_data
        meta_data[key][:options] = collector.options
      end
      meta_data
    end

    def fetch_all_data(options)
      if MetricsMonitor.config.exclude_main_process
        all_data = {}
      else
        all_data = fetch_data(options)
      end
      if @dispatcher
        @dispatcher.dispatch(options).each do |result|
          all_data.merge!(result)
        end
      end
      all_data
    end

    def watch(proc_number)
      @dispatcher.receive(proc_number) do |options|
        fetch_data(options)
      end
    end

    private

    def fetch_data(options)
      collector_name = options[:collector].to_sym
      collector = @collectors[collector_name]
      collector_options = options
      collector.options.merge!(collector_options) if collector_options

      timeout = collector.options[:timeout] / 1000.0 / (1 + @procs.to_i)
      Timeout.timeout(timeout) do
        { Process.pid => collector.fetch_data }
      end
    rescue Timeout::Error => e
      MetricsMonitor.logger.warn("#{options} timeout: #{e}")
      {
        Process.pid => {
          error: e.to_s,
        }
      }
    rescue => e
      MetricsMonitor.logger.error(e.message)
      MetricsMonitor.logger.error(e.backtrace.join("\n"))
      {
        Process.pid => {
          error: e.to_s,
        }
      }
    end
  end
end
