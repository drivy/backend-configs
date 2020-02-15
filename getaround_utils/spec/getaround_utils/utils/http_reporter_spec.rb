require "spec_helper"

describe GetaroundUtils::Utils::HttpReporter do
  let(:url) { 'https://test.com/report' }
  let(:dummy_class) { Class.new(described_class) }
  let(:subject) { dummy_class.new(url: url) }

  it 'perfroms a noop' do
    expect{ subject.report(key: :value) }.not_to raise_error
  end
end
