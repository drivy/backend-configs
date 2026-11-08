# frozen_string_literal: true

require 'spec_helper'
require 'getaround_utils/exposed_hosts/entry'

RSpec.describe GetaroundUtils::ExposedHosts::Entry do
  subject(:entry) { described_class.new(host: 'www.example.com', visibility:, group: 'web') }

  let(:visibility) { :public }

  describe '.build' do
    it 'takes the host and the visibility, and keeps any other key as metadata' do
      expect(described_class.build({ host: 'www.example.com', visibility: 'public', group: 'web', port: 3000 }))
        .to have_attributes(host: 'www.example.com', visibility: :public, metadata: { group: 'web', port: 3000 })
        .and be_frozen
    end

    it 'refuses anything but a hash' do
      expect { described_class.build('www.example.com') }
        .to raise_error(described_class::Error, 'expected a hash, got "www.example.com"')
    end

    it 'requires the host and the visibility' do
      expect { described_class.build({ group: 'web' }) }
        .to raise_error(described_class::Error, 'missing required keys: host, visibility')
    end

    it 'merges its default_url_options over the given ones, out of its metadata' do
      entry = described_class.build(
        { host: 'www.example.com', visibility: 'public', group: 'web', default_url_options: { port: 3001 } },
        default_url_options: { protocol: 'https', port: 3000 },
      )
      expect(entry.metadata).to eq({ group: 'web' })
      expect(entry.url_options).to eq({ protocol: 'https', port: 3001, host: 'www.example.com' })
    end

    it 'refuses default_url_options of the entry that are not a hash or set the host' do
      expect { described_class.build({ host: 'www.example.com', visibility: 'public', default_url_options: 'https' }) }
        .to raise_error(described_class::Error, 'default_url_options must be a hash without host, got "https"')
      expect { described_class.build({ host: 'www.example.com', visibility: 'public', default_url_options: { host: 'other.example.com' } }) }
        .to raise_error(described_class::Error, 'default_url_options must be a hash without host, got {host: "other.example.com"}')
    end

    it 'refuses given default_url_options that are not a hash or set the host' do
      expect { described_class.build({ host: 'www.example.com', visibility: 'public' }, default_url_options: nil) }
        .to raise_error(ArgumentError, 'default_url_options must be a hash without host, got nil')
      expect { described_class.build({ host: 'www.example.com', visibility: 'public' }, default_url_options: { host: 'other.example.com' }) }
        .to raise_error(ArgumentError, 'default_url_options must be a hash without host, got {host: "other.example.com"}')
    end
  end

  describe '.valid_default_url_options?' do
    it 'is true for a hash without host' do
      expect(described_class.valid_default_url_options?({})).to be(true)
      expect(described_class.valid_default_url_options?({ protocol: 'https', port: 3000 })).to be(true)
    end

    it 'is false for anything else' do
      expect(described_class.valid_default_url_options?({ host: 'www.example.com' })).to be(false)
      expect(described_class.valid_default_url_options?(nil)).to be(false)
    end
  end

  describe '.valid_visibility?' do
    it 'is true for public or private, as a Symbol or a String' do
      expect(described_class.valid_visibility?(:public)).to be(true)
      expect(described_class.valid_visibility?('private')).to be(true)
    end

    it 'is false for anything else' do
      expect(described_class.valid_visibility?('Public')).to be(false)
      expect(described_class.valid_visibility?(:internal)).to be(false)
      expect(described_class.valid_visibility?(nil)).to be(false)
    end
  end

  describe '.new' do
    it 'turns the visibility into a symbol' do
      expect(described_class.new(host: 'www.example.com', visibility: 'private').visibility).to eq(:private)
    end

    it 'keeps any other key as metadata' do
      expect(described_class.new(host: 'www.example.com', visibility: :public).metadata).to eq({})
      expect(entry.metadata).to eq({ group: 'web' })
    end

    it 'takes the URL options of its host from the default_url_options' do
      expect(entry.url_options).to eq({ host: 'www.example.com' })
      expect(described_class.new(host: 'www.example.com', visibility: :public, default_url_options: { port: 3000 }).url_options)
        .to eq({ port: 3000, host: 'www.example.com' })
    end

    it 'freezes the entry, its metadata and its URL options' do
      expect(entry).to be_frozen
      expect(entry.metadata).to be_frozen
      expect(entry.url_options).to be_frozen
    end

    {
      'a missing host' => [{ host: nil }, 'host must be a non-empty string, got nil'],
      'an empty host' => [{ host: '' }, 'host must be a non-empty string, got ""'],
      'a host that is not a string' => [{ host: 42 }, 'host must be a non-empty string, got 42'],
      'a host starting with a dot' => [{ host: '.example.com' }, 'host must not start with a dot, got ".example.com"'],
      'a host with a port' => [{ host: 'www.example.com:80' }, 'host must not include a port, got "www.example.com:80"'],
      'a missing visibility' => [{ visibility: nil }, 'visibility must be public or private, got nil'],
      'a capitalized visibility' => [{ visibility: 'Public' }, 'visibility must be public or private, got "Public"'],
      'an unknown visibility' => [{ visibility: 'internal' }, 'visibility must be public or private, got "internal"'],
      'default_url_options that are not a hash' => [{ default_url_options: nil }, 'default_url_options must be a hash without host, got nil'],
      'default_url_options that set the host' => [
        { default_url_options: { host: 'other.example.com' } },
        'default_url_options must be a hash without host, got {host: "other.example.com"}',
      ],
    }.each do |description, (attributes, message)|
      context "with #{description}" do
        let(:valid_attributes) { { host: 'www.example.com', visibility: 'public' } }

        it { expect { described_class.new(**valid_attributes, **attributes) }.to raise_error(described_class::Error, message) }
      end
    end
  end

  context 'with a public visibility' do
    it { is_expected.to be_public }
    it { is_expected.not_to be_private }
  end

  context 'with a private visibility' do
    let(:visibility) { :private }

    it { is_expected.to be_private }
    it { is_expected.not_to be_public }
  end

  describe '#match?' do
    it 'is true without criteria' do
      expect(entry.match?).to be(true)
    end

    it 'is true only when the host, the visibility and the metadata all match' do
      expect(entry.match?(host: 'www.example.com', visibility: :public, group: 'web')).to be(true)
      expect(entry.match?(host: 'api.example.com', visibility: :public, group: 'web')).to be(false)
      expect(entry.match?(host: 'www.example.com', visibility: :private, group: 'web')).to be(false)
      expect(entry.match?(host: 'www.example.com', visibility: :public, group: 'api')).to be(false)
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

    context 'with a visibility' do
      it 'is true for the visibility of the entry, as a Symbol or a String' do
        expect(entry.match?(visibility: :public)).to be(true)
        expect(entry.match?(visibility: 'public')).to be(true)
      end

      it 'is false for the other visibility' do
        expect(entry.match?(visibility: :private)).to be(false)
      end

      it 'refuses an unknown visibility' do
        expect { entry.match?(visibility: :internal) }
          .to raise_error(ArgumentError, 'visibility must be public or private, got :internal')
      end

      it 'refuses a nil visibility, unlike a visibility left out' do
        expect { entry.match?(visibility: nil) }
          .to raise_error(ArgumentError, 'visibility must be public or private, got nil')
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
      subject(:entry) { described_class.new(host: 'www.example.com', visibility: :public, group: :web) }

      it 'takes a Symbol or a String with the same name' do
        expect(entry.match?(group: :web)).to be(true)
        expect(entry.match?(group: 'web')).to be(true)
      end
    end

    context 'with a value that is neither a String nor a Symbol' do
      subject(:entry) { described_class.new(host: 'www.example.com', visibility: :public, port: 3000) }

      it 'compares it strictly' do
        expect(entry.match?(port: 3000)).to be(true)
        expect(entry.match?(port: '3000')).to be(false)
      end
    end
  end

  describe '#to_h' do
    it 'puts the metadata next to the host and the visibility, without the URL options' do
      entry = described_class.new(host: 'www.example.com', visibility: :public, default_url_options: { port: 3000 }, group: 'web')
      expect(entry.to_h).to eq({ host: 'www.example.com', visibility: :public, group: 'web' })
    end
  end
end
