# frozen_string_literal: true

require 'spec_helper'
require 'getaround_utils/exposed_hosts/undeclared_host'

RSpec.describe GetaroundUtils::ExposedHosts::UndeclaredHost do
  it 'tells that no host is declared' do
    expect(described_class.new.message).to eq('no host is declared')
  end

  context 'with an exposure' do
    it 'names the exposure' do
      expect(described_class.new(exposure: :internal).message).to eq('no internal host is declared')
    end
  end

  context 'with metadata' do
    it 'names the metadata' do
      expect(described_class.new(group: :api).message).to eq('no host matching {group: :api} is declared')
    end
  end

  context 'with an exposure and metadata' do
    it 'names both' do
      expect(described_class.new(exposure: :internal, group: 'api').message)
        .to eq('no internal host matching {group: "api"} is declared')
    end
  end
end
