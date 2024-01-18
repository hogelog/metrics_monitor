require "objspace"

module MetricsMonitor
  module Collector
    class ObjectStatCollector < CollectorBase

      def self.default_options
        { enabled: true, interval: 240_000, target_classes: nil, ignore_classes: [], memsize_threshold: 0 }
      end

      def meta_data
        {
          title: "Object Stat",
          monitors: [
            { key: :stat, title: "Object sizes", type: :chart, mode: :stacked_bar, size: :full, hovertemplate: "%{y} bytes" },
          ],
          data: {
            stat: { mode: "append" },
          },
        }
      end

      def data
        stat = []
        classes = options[:target_classes] || ObjectSpace.each_object(Class)
        classes.each do |klass|
          next if options[:ignore_classes].include?(klass)
          next unless klass.respond_to?(:name)
          next unless klass.method(:name).arity == 0
          name = klass.name
          next unless name
          size = ObjectSpace.memsize_of_all(klass)
          next if size <= options[:memsize_threshold]
          stat << [name, size]
        end
        stat.sort_by!{|_name, size| -size }

        {
          stat:,
        }
      end
    end
  end
end
