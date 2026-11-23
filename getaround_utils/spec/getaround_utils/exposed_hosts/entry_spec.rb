# frozen_string_literal: true

require 'spec_helper'
require 'getaround_utils/exposed_hosts/entry'

RSpec.describe GetaroundUtils::ExposedHosts::Entry do
  subject(:entry) { described_class.new(host: 'www.example.com', exposure:, group: 'web') }

  let(:exposure) { :external }

  describe '.build' do
    it 'takes the host and the exposure, and keeps any other key as metadata' do
      expect(described_class.build({ host: 'www.example.com', exposure: 'external', group: 'web', port: 3000 }))
        .to have_attributes(host: 'www.example.com', exposure: :external, metadata: { group: 'web', port: 3000 })
    end

    it 'refuses anything but a hash' do
      expect { described_class.build('www.example.com') }
        .to raise_error(described_class::Error, 'expected a hash, got "www.example.com"')
    end

    it 'requires the host and the exposure' do
      expect { described_class.build({ group: 'web' }) }
        .to raise_error(described_class::Error, 'missing required keys: host, exposure')
    end
  end

  describe '.new' do
    it 'turns the exposure into a symbol' do
      expect(described_class.new(host: 'www.example.com', exposure: 'internal').exposure).to eq(:internal)
    end

    it 'keeps any other key as metadata' do
      expect(described_class.new(host: 'www.example.com', exposure: :external).metadata).to eq({})
      expect(entry.metadata).to eq({ group: 'web' })
    end

    it 'freezes its host and its metadata' do
      expect(described_class.new(host: +'www.example.com', exposure: :external, group: 'web'))
        .to have_attributes(host: be_frozen, metadata: be_frozen)
    end

    {
      'a missing host' => [nil, 'host must be a non-empty string, got nil'],
      'an empty host' => ['', 'host must be a non-empty string, got ""'],
      'a host that is not a string' => [42, 'host must be a non-empty string, got 42'],
      'a host starting with a dot' => ['.example.com', 'host must not start with a dot, got ".example.com"'],
      'a host with a port' => ['www.example.com:80', 'host must not include a port, got "www.example.com:80"'],
    }.each do |description, (host, message)|
      context "with #{description}" do
        it { expect { described_class.new(host:, exposure: 'external') }.to raise_error(described_class::Error, message) }
      end
    end

    {
      'a missing exposure' => [nil, 'exposure must be external or internal, got nil'],
      'a capitalized exposure' => ['External', 'exposure must be external or internal, got "External"'],
      'an unknown exposure' => ['public', 'exposure must be external or internal, got "public"'],
    }.each do |description, (exposure, message)|
      context "with #{description}" do
        it { expect { described_class.new(host: 'www.example.com', exposure:) }.to raise_error(described_class::Error, message) }
      end
    end
  end

  context 'with an external exposure' do
    it { is_expected.to be_external }
    it { is_expected.not_to be_internal }
  end

  context 'with an internal exposure' do
    let(:exposure) { :internal }

    it { is_expected.to be_internal }
    it { is_expected.not_to be_external }
  end

  describe '#match?' do
    it 'is true without criteria' do
      expect(entry.match?).to be(true)
    end

    it 'is true only when the host, the exposure and the metadata all match' do
      expect(entry.match?(host: 'www.example.com', exposure: :external, group: 'web')).to be(true)
      expect(entry.match?(host: 'api.example.com', exposure: :external, group: 'web')).to be(false)
      expect(entry.match?(host: 'www.example.com', exposure: :internal, group: 'web')).to be(false)
      expect(entry.match?(host: 'www.example.com', exposure: :external, group: 'api')).to be(false)
    end

    context 'with a host' do
      %w[www.example.com WWW.Example.com www.example.com:3000].each do |authority|
        it "is true for #{authority}" do
          expect(entry.match?(host: authority)).to be(true)
        end
      end

      %w[api.example.com wwwxexample.com www.example.com.evil.example evil.www.example.com].each do |authority|
        it "is false for #{authority}" do
          expect(entry.match?(host: authority)).to be(false)
        end
      end

      it 'is false for a nil host, that of a request without a Host header' do
        expect(entry.match?(host: nil)).to be(false)
      end
    end

    context 'with an exposure' do
      it 'is true for the exposure of the entry, as a Symbol or a String' do
        expect(entry.match?(exposure: :external)).to be(true)
        expect(entry.match?(exposure: 'external')).to be(true)
      end

      it 'is false for the other exposure' do
        expect(entry.match?(exposure: :internal)).to be(false)
      end

      it 'is false for an unknown exposure' do
        expect(entry.match?(exposure: :public)).to be(false)
      end

      it 'is false for a nil exposure, unlike an exposure left out' do
        expect(entry.match?(exposure: nil)).to be(false)
      end
    end

    context 'with metadata' do
      it 'is true when the metadata holds the given keys and values' do
        expect(entry.match?(group: 'web')).to be(true)
      end

      it 'is false for another value' do
        expect(entry.match?(group: 'api')).to be(false)
      end

      it 'is false for a key the metadata does not hold' do
        expect(entry.match?(group: 'web', locale: 'fr')).to be(false)
      end

      it 'is false for a key the metadata does not hold, even with a nil value' do
        expect(entry.match?(locale: nil)).to be(false)
      end

      it 'takes a Symbol for a String value with the same name' do
        expect(entry.match?(group: :web)).to be(true)
      end
    end

    context 'with a Symbol value' do
      subject(:entry) { described_class.new(host: 'www.example.com', exposure: :external, group: :web) }

      it 'takes a Symbol or a String with the same name' do
        expect(entry.match?(group: :web)).to be(true)
        expect(entry.match?(group: 'web')).to be(true)
      end
    end

    context 'with a value that is neither a String nor a Symbol' do
      subject(:entry) { described_class.new(host: 'www.example.com', exposure: :external, port: 3000) }

      it 'compares it strictly' do
        expect(entry.match?(port: 3000)).to be(true)
        expect(entry.match?(port: '3000')).to be(false)
      end
    end
  end

  describe '#to_h' do
    it 'puts the metadata next to the host and the exposure' do
      expect(entry.to_h).to eq({ host: 'www.example.com', exposure: :external, group: 'web' })
    end
  end
end
