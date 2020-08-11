require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :before_build do
  chdir "visualizer" do
    rm Dir.glob("dist/*")
    sh "yarn", "build"
  end
end

task build: :before_build