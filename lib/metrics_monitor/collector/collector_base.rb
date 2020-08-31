module MetricsMonitor
  module Collector
    class CollectorBase
      attr_reader :options

      def self.configure
        yield(options)
        options
      end

      def self.options
        @options ||= default_options.dup
      end

      def self.default_options
        { enabled: true }
      end

      def initialize
        @options = self.class.options.dup
      end

      def key
        @key ||= self.class.name.split("::")[-1].to_sym
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
