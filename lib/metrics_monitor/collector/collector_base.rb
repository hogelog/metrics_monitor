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
        raise NotImplementedError
      end

      def initialize
        @options = self.class.options.dup
      end

      def start
        @metrics = []
        @metrics_mutex = Mutex.new
        @thread = Thread.new do
          MetricsMonitor.logger.info "#{self.class.name}: start"
          while true
            data = collect_data
            @metrics_mutex.synchronize do
              @metrics << data
            end
            sleep(options[:interval] / 1000.0)
          end
        end

        at_exit do
          @thread.kill
        end
      end

      def fetch_metrics
        @metrics_mutex.synchronize do
          metrics = @metrics.dup
          @metrics.clear
          metrics
        end
      end

      def key
        @key ||= self.class.name.split("::")[-1].to_sym
      end

      def fetch_meta_data
        meta_data.merge(key: key)
      end

      def collect_data
        { ts: Time.now.to_f, data: data }
      end
    end
  end
end
