RSpec.describe MetricsMonitor::Collector::BasicCollector do
  let(:collector) { MetricsMonitor::Collector::BasicCollector.new }

  it "#meta_data" do
    expect(collector.meta_data[:monitors]).to be_kind_of(Array)
  end

  it "#data" do
    expect(collector.data).to be_kind_of(Hash)
  end
end