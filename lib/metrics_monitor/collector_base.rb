module MetricsMonitor
  class CollectorBase
    def collect
      data = calculate
      { ts: Time.now.to_f, data: data }
    rescue => e
      {
        error: e.to_s,
        backtrace: e&.backtrace
      }
    end
  end
end
