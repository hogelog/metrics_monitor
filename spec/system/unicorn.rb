preload_app true

worker_processes 2

after_fork do |server, worker|
  server.logger.info("worker=#{worker.nr} spawned pid=#{$$}")
  MetricsMonitor.monitor.watch(worker.nr)
end
