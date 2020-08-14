require "objspace"
require "open3"

module MetricsMonitor
  class BasicCollector < CollectorBase
    PS_PATTERN = /\A\s*(?<pid>\d+)\s+(?<ppid>\d+)\s+(?<cpu>\d+\.\d)\s+(?<mem>\d+\.\d)\s+(?<rss>\d+)\s+(?<vsz>\d+)\s*\z/
    PS_OPTION = "pid,ppid,%cpu,%mem,rss,vsz"

    def initialize
      @pid = Process.pid
    end

    def meta
      {
        title: "Basic Collector",
        chart_formats: [
          { key: :process, title: "Process", type: :line },
          { key: :cpu, title: "CPU", type: :area },
          { key: :mem, title: "MEM", type: :area },
          { key: :rss, title: "RSS", type: :area },
          { key: :vsz, title: "VSZ", type: :area },
        ]
      }
    end

    def calculate
      calculate_ps
    end

    private

    def calculate_ps
      pids = [@pid]
      output, error, status = Open3.capture3("ps", "-o", PS_OPTION)

      if status.success?
        total_cpu = 0.0
        total_mem = 0.0
        total_rss = 0
        total_vsz = 0

        output.each_line do |line|
          match = PS_PATTERN.match(line)
          next unless match
          pid = match[:pid].to_i
          ppid = match[:ppid].to_i
          cpu = match[:cpu].to_f
          mem = match[:mem].to_f
          rss = match[:rss].to_i
          vsz = match[:vsz].to_i

          if pids.include?(ppid)
            pids << pid
          elsif pid != @pid
            next
          end

          total_cpu += cpu
          total_mem += mem
          total_rss += rss
          total_vsz += vsz
        end
        {
          process: pids.size,
          cpu: total_cpu,
          mem: total_mem,
          rss: total_rss,
          vsz: total_vsz,
        }
      else
        raise MetricsMonitor::Error, error
      end
    end
  end
end
