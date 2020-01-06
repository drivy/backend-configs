require "spec_helper"

describe GetaroundUtils::Utils::HttpReporter do
  let(:url) { 'https://test.com/report' }
  let(:dummy_class) { Class.new(described_class) }
  let(:subject) { dummy_class.new(url: url) }

  after do
    dummy_class::AsyncQueue.reset
  end

  it 'posts the event payload to the configured endpoint' do
    stub = stub_request(:post, "https://test.com/report").with(
      headers: { 'Content-Type' => 'application/json' },
      body: '{"key":"value"}',
    )
    subject.report(key: :value)
    dummy_class::AsyncQueue.terminate

    expect(stub).to have_been_requested
  end
end
