require "objspace"

module MetricsMonitor
  module Collector
    class ObjectStatCollector < CollectorBase

      def self.default_options
        { enabled: false, timeout: 120_000 }
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
          next unless klass.respond_to?(:name)
          next unless klass.method(:name).parameters.empty?
          next unless klass.name
          size = ObjectSpace.memsize_of_all(klass)
          next if size == 0
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
