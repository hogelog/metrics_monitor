module MetricsMonitor
  module Collector
    class GcStatCollector < CollectorBase
      def meta_data
        {
            title: "GC Stat",
            monitors: [
                { key: :heap_live_slots, title: "Heap live slots", type: :chart, mode: :area },
                { key: :heap_free_slots, title: "Heap free slots", type: :chart, mode: :area },
                { key: :total_allocated_objects, title: "Total allocated objects", type: :chart, mode: :line },
                { key: :total_freed_objects, title: "Total freed objects", type: :chart, mode: :line },
            ],
            data: {
              heap_live_slots: { mode: "append" },
              heap_free_slots: { mode: "append" },
              total_allocated_objects: { mode: "append" },
              total_freed_objects: { mode: "append" },
            },
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
