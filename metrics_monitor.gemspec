require_relative 'lib/metrics_monitor/version'

Gem::Specification.new do |spec|
  spec.name          = "metrics_monitor"
  spec.version       = MetricsMonitor::VERSION
  spec.authors       = ["hogelog"]
  spec.email         = ["konbu.komuro@gmail.com"]

  spec.summary       = %q{Metrics monitor via HTTP}
  spec.description   = spec.summary 
  spec.homepage      = "https://github.com/hogelog/metrics_monitor"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.files        += Dir.glob(File.join("visualizer", "dist", "*"))
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "webrick"

  spec.add_development_dependency "rack"
  spec.add_development_dependency "unicorn"
end
