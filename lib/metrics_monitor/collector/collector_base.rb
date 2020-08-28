module MetricsMonitor
  module Collector
    class CollectorBase
      def self.configure
        @options = {}.dup
        yield(@options)
        @options
      end

      def self.options
        @options
      end

      def key
        @key ||= self.class.name.split("::")[-1]
      end

      def fetch_meta_data
        meta_data.merge(key: key)
      end

      def fetch_data
        { ts: Time.now.to_f, data: data }
      end
    end
  end
end
