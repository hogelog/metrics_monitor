require "open3"

module MetricsMonitor
  module Collector
    class BasicCollector < CollectorBase
      PS_PATTERN = /\A\s*(?<cpu>\d+\.\d)\s+(?<mem>\d+\.\d)\s+(?<rss>\d+)\s+(?<vsz>\d+)\s*\z/
      PS_OPTION = "%cpu,%mem,rss,vsz"

      def meta_data
        {
          title: "Basic",
          chart_formats: [
            { key: :cpu, title: "CPU", type: :area },
            { key: :mem, title: "MEM", type: :area },
            { key: :rss, title: "RSS", type: :area },
            { key: :vsz, title: "VSZ", type: :area },
          ],
        }
      end

      def data
        output, error, status = Open3.capture3("ps", "-p", Process.pid.to_s, "-o", PS_OPTION)

        if status.success?
          output.each_line do |line|
            match = PS_PATTERN.match(line)
            next unless match
            cpu = match[:cpu].to_f
            mem = match[:mem].to_f
            rss = match[:rss].to_i
            vsz = match[:vsz].to_i

            return {
              cpu: cpu,
              mem: mem,
              rss: rss,
              vsz: vsz,
            }
          end
        else
          raise MetricsMonitor::Error, error
        end

        nil
      end
    end
  end
end
