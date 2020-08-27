begin
  require "memprof2"
ensure LoadError
end

module MetricsMonitor
  module Collector
    class Memprof2Collector < CollectorBase
      DEFAULT_OPTIONS = {}.freeze

      def self.configure
        @options = DEFAULT_OPTIONS.dup
        yield(@options)
        @options
      end

      def self.options
        @options
      end

      def initialize
        super
      end

      def meta_data
        {
          title: "Memory profile",
          monitors: [
            { key: :report, title: "Allocation sourcefiles (live objects)", type: :text },
          ],
          data: {
            report: { mode: "overwrite" },
          },
        }
      end

      def data
        unless @running
          @running = true
          Memprof2.start
        end

        ObjectSpace.trace_object_allocations_stop
        profiler = Memprof2.new
        profiler.configure(Memprof2Collector.options)
        results = profiler.collect_info
        report = results.to_a.sort_by{|_line, size| -size }.map{|line, size| "#{line}\t#{size}" }.join("\n")
        {
          report: report,
        }
      ensure
        ObjectSpace.trace_object_allocations_start
      end
    end
  end
end
