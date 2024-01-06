require "objspace"

module MetricsMonitor
  module Collector
    class ObjectTraceCollector < CollectorBase

      def self.default_options
        { enabled: false, interval: 60_000 }
      end

      def meta_data
        {
          title: "Object Trace",
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
          ObjectSpace.trace_object_allocations_start
        end

        ObjectSpace.trace_object_allocations_stop

        results = {}
        ObjectSpace.each_object do |o|
          file = ObjectSpace.allocation_sourcefile(o)
          next unless file
          line = ObjectSpace.allocation_sourceline(o)
          memsize = ObjectSpace.memsize_of(o)
          klass_name = o.class rescue "???"
          location = "#{file}:#{line}:#{klass_name}"
          results[location] ||= 0
          results[location] += memsize
        end

        report = results.to_a.sort_by{|_loc, size| -size }.map{|loc, size| "#{loc}\t#{size}" }.join("\n")
        {
          report: report,
        }
      ensure
        ObjectSpace.trace_object_allocations_start
      end
    end
  end
end
