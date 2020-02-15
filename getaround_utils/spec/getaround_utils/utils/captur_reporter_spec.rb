require "spec_helper"

describe GetaroundUtils::Utils::CapturReporter do
  let(:url) { 'https://test.com/push/getaround_utils-rspec' }
  let(:metas) { Hash(metas_key: 'meta_value') }
  let(:subject) { described_class.new }
  let(:timestamp) { DateTime.now.iso8601 }

  let(:event) { Hash(uuid: '00000000-0000-0000-0000-000000000001', type: :event, timestamp: timestamp, anonymous_id: 'unknown', attributes: { id: '1' }) }

  before do
    stub_const("#{described_class.name}::CAPTUR_URL", url)
  end

  after do
    subject.terminate
  end

  describe 'functional tests' do
    it 'posts the event payload to the configured endpoint' do
      stub = stub_request(:post, url).with(
        headers: { 'Content-Type' => 'application/json' },
        body: { events: [event], metas: {} }.to_json,
      )
      subject.push(event)
      subject.terminate
      expect(stub).to have_been_requested
    end

    it 'groups events together' do
      stub = stub_request(:post, url).with(
        headers: { 'Content-Type' => 'application/json' },
        body: { events: [event, event], metas: {} }.to_json,
      )
      subject.push(event)
      subject.push(event)
      subject.terminate
      expect(stub).to have_been_requested
    end

    it 'allow describing custom metas' do
      stub = stub_request(:post, url).with(
        headers: { 'Content-Type' => 'application/json' },
        body: { events: [event], metas: metas }.to_json,
      )
      allow(subject).to receive(:metas)
        .and_return(metas)
      subject.push(event)
      subject.terminate
      expect(stub).to have_been_requested
    end
  end
end
