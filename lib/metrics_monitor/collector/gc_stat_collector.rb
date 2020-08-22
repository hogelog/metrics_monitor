require "timeout"

module MetricsMonitor
  module Collector
    class GcStatCollector < CollectorBase
      def meta_data
        {
            title: "GC Stat",
            chart_formats: [
                { key: :heap_live_slots, title: "Heap live slots", type: :area },
                { key: :heap_free_slots, title: "Heap free slots", type: :area },
                { key: :total_allocated_objects, title: "Total allocated objects", type: :line },
                { key: :total_freed_objects, title: "Total freed objects", type: :line },
            ],
        }
      end

      def data
        stat = GC.stat
        {
            heap_live_slots: stat[:heap_live_slots],
            heap_free_slots: stat[:heap_free_slots],
            total_allocated_objects: stat[:total_allocated_objects],
            total_freed_objects: stat[:total_freed_objects],
        }
      end
    end
  end
end
