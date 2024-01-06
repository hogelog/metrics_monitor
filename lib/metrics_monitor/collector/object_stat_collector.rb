require "objspace"

module MetricsMonitor
  module Collector
    class ObjectStatCollector < CollectorBase

      def self.default_options
        { enabled: true, interval: 240_000, ignore_classes: [], memsize_threshold: 0 }
      end

      def meta_data
        {
          title: "Object Stat",
          monitors: [
            { key: :stat, title: "Object sizes", type: :text },
          ],
          data: {
            stat: { mode: "overwrite" },
          },
        }
      end

      def data
        stat = []
        ObjectSpace.each_object(Class).each do |klass|
          next if options[:ignore_classes].include?(klass)
          next unless klass.respond_to?(:name)
          next unless klass.method(:name).arity == 0
          next unless klass.name
          size = ObjectSpace.memsize_of_all(klass)
          next if size <= options[:memsize_threshold]
          stat << [klass.name, size]
        end
        stat.sort_by!{|_name, size| -size }

        {
          stat: stat.map{|name, size| "#{name}\t#{size}" }.join("\n"),
        }
      end
    end
  end
end
