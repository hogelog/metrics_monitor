require "objspace"

module MetricsMonitor
  module Collector
    class ObjectTraceCollector < CollectorBase

      def self.default_options
        { enabled: true, interval: 60_000, target_classes: nil, ignore_classes: [] }
      end

      def meta_data
        {
          title: "Object Trace",
          monitors: [
            { key: :report, title: "Allocation sourcefiles (live objects)", type: :chart, mode: :stacked_bar, size: :full, hovertemplate: "%{y} bytes" }
          ],
          data: {
            report: { mode: "append" },
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
        classes = options[:target_classes] || ObjectSpace.each_object(Class)
        classes.each do |klass|
          next if options[:ignore_classes].include?(klass)
          ObjectSpace.each_object(klass) do |o|
            file = ObjectSpace.allocation_sourcefile(o)
            next unless file
            line = ObjectSpace.allocation_sourceline(o)
            memsize = ObjectSpace.memsize_of(o)
            klass_name = o.class rescue "???"
            location = "#{file}:#{line}:#{klass_name}"
            results[location] ||= 0
            results[location] += memsize
          end
        end

        report = results.to_a.sort_by{|_loc, size| -size }.map{|loc, size| [loc, size] }
        {
          report:,
        }
      ensure
        ObjectSpace.trace_object_allocations_start
      end
    end
  end
end
