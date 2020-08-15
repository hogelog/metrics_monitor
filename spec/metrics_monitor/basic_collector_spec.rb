RSpec.describe MetricsMonitor::BasicCollector do
  let(:collector) { MetricsMonitor::BasicCollector.new }

  it "#meta" do
    expect(collector.meta[:chart_formats]).to be_kind_of(Array)
  end

  it "#calculate" do
    expect(collector.calculate).to be_kind_of(Hash)
  end
end