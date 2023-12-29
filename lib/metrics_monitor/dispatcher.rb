require "securerandom"

module MetricsMonitor
  class Dispatcher
    def initialize(procs)
      @procs = procs

      @dispatch_readers = []
      @dispatch_writers = []
      @procs.times do |i|
        @dispatch_readers[i], @dispatch_writers[i] = IO.pipe
      end

      @result_reader, @result_writer = IO.pipe

      @mutex = Thread::Mutex.new
    end

    def receive(proc_number)
      dispatch_reader = @dispatch_readers[proc_number]

      @result_reader.close
      @dispatch_writers.each do |writer|
        writer.close
      end

      @thread = Thread.new do
        MetricsMonitor.logger.info "watch: #{Process.pid}"
        while json = dispatch_reader.gets
          options = JSON.parse(json, symbolize_names: true)
          dispatch_id = options[:dispatch_id]
          data = yield(options)
          @result_writer.puts(JSON.fast_generate({ dispatch_id:, data: }))
        end
      end

      at_exit do
        if @thread.alive?
          @thread.wakeup
          @thread.join
        end
      end
    end

    def dispatch(options)
      return {} if @procs == 0

      dispatch_id = SecureRandom.hex(12)

      @mutex.synchronize do
        json_options = JSON.fast_generate(options.merge(dispatch_id: dispatch_id))
        @dispatch_writers.each do |dispatch_writer|
          dispatch_writer.puts(json_options)
        end
        children_data = []
        @procs.times do
          json = @result_reader.gets
          result = JSON.parse(json, symbolize_names: true)
          children_data << result[:data]
        end
        children_data
      end
    end
  end
end
