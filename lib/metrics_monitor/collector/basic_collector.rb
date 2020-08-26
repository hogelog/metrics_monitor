require "open3"

module MetricsMonitor
  module Collector
    class BasicCollector < CollectorBase
      PS_PATTERN = /\A\s*(?<pid>\d+)\s+(?<cpu>\d+\.\d)\s+(?<mem>\d+\.\d)\s+(?<rss>\d+)\s+(?<vsz>\d+)\s+(?<command>.+)\s*\z/
      PS_OPTION = "pid,%cpu,%mem,rss,vsz,command"

      def meta_data
        {
          title: "Basic",
          monitors: [
            { key: "pid,command,cpu,mem,rss,vsz", title: "CPU", type: :table },
            { key: :cpu, title: "CPU", type: :chart, mode: :area },
            { key: :mem, title: "MEM", type: :chart, mode: :area },
            { key: :rss, title: "RSS", type: :chart, mode: :area },
            { key: :vsz, title: "VSZ", type: :chart, mode: :area },
          ],
        }
      end

      def data
        output, error, status = Open3.capture3("ps", "-p", Process.pid.to_s, "-o", PS_OPTION)

        if status.success?
          output.each_line do |line|
            match = PS_PATTERN.match(line)
            next unless match
            pid = match[:pid].to_i
            cpu = match[:cpu].to_f
            mem = match[:mem].to_f
            rss = match[:rss].to_i
            vsz = match[:vsz].to_i
            command = match[:command].strip

            return {
              pid: pid,
              cpu: cpu,
              mem: mem,
              rss: rss,
              vsz: vsz,
              command: command,
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
