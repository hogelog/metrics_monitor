require "metrics_monitor/monitor/unicorn"

require "timeout"

module MetricsMonitor
  class Monitor
    WAIT_LIMIT_DISPATCH_CHILD = 0.5

    def initialize(collector_classes, procs: nil)
      @parent_pid = Process.pid

      @collectors = {}
      collector_classes.each do |klass|
        collector = klass.new
        @collectors[collector.key] = collector
      end

      @result_reader, @result_writer = IO.pipe

      procs ||= MetricsMonitor::Monitor::Unicorn.worker_processes
      @dispatch_readers = []
      @dispatch_writers = []
      procs.to_i.times do |i|
        @dispatch_readers[i], @dispatch_writers[i] = IO.pipe
      end
    end

    def fetch_all_data(options)
      if MetricsMonitor.config.exclude_main_process
        all_data = {}
      else
        all_data = {
          Process.pid => fetch_data(options),
        }
      end
      all_data.merge(fetch_data_from_children(options))
    end

    def fetch_meta_data
      meta_data = {}
      @collectors.each do |key, collector|
        meta_data[key] = collector.fetch_meta_data
        meta_data[key][:options] = collector.options
      end
      meta_data
    end

    def watch(proc_number)
      dispatch_reader = @dispatch_readers[proc_number]

      @result_reader.close
      @dispatch_writers.each do |writer|
        writer.close
      end

      @thread = Thread.new do
        MetricsMonitor.logger.info "watch: #{Process.pid}"
        while json = dispatch_reader.gets
          options = JSON.parse(json, symbolize_names: true)
          child_data = { pid: Process.pid, data: fetch_data(options) }
          @result_writer.puts(JSON.fast_generate(child_data))
        end
      end

      at_exit do
        if @thread.alive?
          @thread.wakeup
          @thread.join
        end
      end
    end

    private

    def fetch_data(options)
      data = {}
      @collectors.each do |key, collector|
        collector_options = options[collector.key]
        collector.options.merge!(collector_options) if collector_options

        next unless collector.options[:enabled]
        data[key] = collector.fetch_data
      end
      data
    rescue => e
      {
          error: e.to_s,
          backtrace: e&.backtrace
      }
    end

    def fetch_data_from_children(options)
      return {} if @dispatch_writers.size == 0

      json_options = JSON.fast_generate(options)
      @dispatch_writers.each do |dispatch_writer|
        dispatch_writer.puts(json_options)
      end
      children_data = {}
      @dispatch_writers.size.times do
        begin
          json = Timeout.timeout(WAIT_LIMIT_DISPATCH_CHILD) do
            @result_reader.gets
          end
          child_data = JSON.parse(json, symbolize_names: true)
          children_data[child_data[:pid]] = child_data[:data]
        rescue => e
          MetricsMonitor.logger.warn("Timeout: #{e}")
        end
      end
      children_data
    end
  end
end
