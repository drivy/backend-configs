# frozen_string_literal: true

require 'spec_helper'
require 'getaround_utils/exposed_hosts/configuration'

RSpec.describe GetaroundUtils::ExposedHosts::Configuration do
  subject(:exposed_hosts) { described_class.new(section) }

  let(:section) { { hosts: entries } }
  let(:entries) do
    [
      { host: 'private.example.com', visibility: 'private', group: 'internal' },
      { host: 'admin.example.com', visibility: :private },
      { host: 'www.example.com', visibility: 'public', port: 3000 },
      { host: 'public.example.com', visibility: 'public' },
    ]
  end

  describe '#entries' do
    it 'keeps the entries in order, with a symbol visibility and the other keys as metadata' do
      expect(exposed_hosts.entries.map(&:to_h)).to eq([
        { host: 'private.example.com', visibility: :private, group: 'internal' },
        { host: 'admin.example.com', visibility: :private },
        { host: 'www.example.com', visibility: :public, port: 3000 },
        { host: 'public.example.com', visibility: :public },
      ])
    end

    it 'freezes the list, its entries and their metadata' do
      expect(exposed_hosts.entries).to be_frozen.and(all(be_frozen))
      expect(exposed_hosts.entries.map(&:metadata)).to all(be_frozen)
      expect(exposed_hosts.entries(:public, port: 3000)).to be_frozen
    end

    context 'with a host declared several times, in both visibilities' do
      let(:entries) do
        [
          { host: 'www.example.com', visibility: 'private' },
          { host: 'www.example.com', visibility: 'public' },
          { host: 'www.example.com', visibility: 'public', group: 'legacy' },
        ]
      end

      it 'keeps every entry' do
        expect(exposed_hosts.entries.map(&:visibility)).to eq(%i[private public public])
      end
    end

    context 'with a visibility' do
      it 'lists the entries of the visibility, in order' do
        expect(exposed_hosts.entries(:public).map(&:host)).to eq(%w[www.example.com public.example.com])
        expect(exposed_hosts.entries(:private).map(&:host)).to eq(%w[private.example.com admin.example.com])
      end
    end

    context 'with a visibility given as a String' do
      it { expect(exposed_hosts.entries('private')).to eq(exposed_hosts.entries(:private)) }
    end

    context 'without entry of the visibility' do
      let(:entries) { [{ host: 'private.example.com', visibility: 'private' }] }

      it { expect { exposed_hosts.entries(:public) }.to raise_error(KeyError, 'exposed_hosts: no public host is declared') }
    end

    context 'with an unknown visibility' do
      it { expect { exposed_hosts.entries(:internal) }.to raise_error(ArgumentError, 'visibility must be public or private, got :internal') }
    end
  end

  describe '#hosts' do
    it 'lists every declared host, in order' do
      expect(exposed_hosts.hosts).to eq(%w[private.example.com admin.example.com www.example.com public.example.com])
    end

    it 'is frozen' do
      expect(exposed_hosts.hosts).to be_frozen
    end

    context 'with a host declared several times, in both visibilities' do
      let(:entries) do
        [
          { host: 'www.example.com', visibility: 'private' },
          { host: 'admin.example.com', visibility: 'private' },
          { host: 'www.example.com', visibility: 'public' },
        ]
      end

      it 'lists it once' do
        expect(exposed_hosts.hosts).to eq(%w[www.example.com admin.example.com])
      end
    end
  end

  describe '#entry' do
    it 'is the first entry' do
      expect(exposed_hosts.entry.host).to eq('private.example.com')
    end

    context 'with a visibility' do
      it 'is the first entry of the visibility' do
        expect(exposed_hosts.entry(:public).host).to eq('www.example.com')
        expect(exposed_hosts.entry(:private).host).to eq('private.example.com')
      end
    end

    context 'without entry of the visibility' do
      let(:entries) { [{ host: 'private.example.com', visibility: 'private' }] }

      it { expect { exposed_hosts.entry(:public) }.to raise_error(KeyError, 'exposed_hosts: no public host is declared') }
    end

    context 'with an unknown visibility' do
      it { expect { exposed_hosts.entry(:internal) }.to raise_error(ArgumentError, 'visibility must be public or private, got :internal') }
    end
  end

  describe '#default_url_options' do
    it 'is empty by default' do
      expect(exposed_hosts.default_url_options).to eq({})
    end

    it 'leaves the URL options of the entries to their host' do
      expect(exposed_hosts.entries.map(&:url_options)).to eq([
        { host: 'private.example.com' },
        { host: 'admin.example.com' },
        { host: 'www.example.com' },
        { host: 'public.example.com' },
      ])
    end

    context 'with default_url_options' do
      let(:section) do
        {
          hosts: [
            { host: 'www.example.com', visibility: 'public', default_url_options: { port: 3000 } },
            { host: 'public.example.com', visibility: 'public' },
          ],
          default_url_options: { protocol: 'https', port: 443 },
        }
      end

      it 'keeps them, frozen' do
        expect(exposed_hosts.default_url_options).to eq({ protocol: 'https', port: 443 }).and be_frozen
      end

      it 'merges into the URL options of every entry, under those of the entry' do
        expect(exposed_hosts.entries.map(&:url_options)).to eq([
          { protocol: 'https', port: 3000, host: 'www.example.com' },
          { protocol: 'https', port: 443, host: 'public.example.com' },
        ])
      end
    end
  end

  context 'with metadata' do
    let(:entries) do
      [
        { host: 'admin.example.com', visibility: 'private', group: 'backoffice' },
        { host: 'api-internal.example.com', visibility: 'private', group: 'api' },
        { host: 'www.example.com', visibility: 'public', group: 'web' },
        { host: 'api.example.com', visibility: 'public', group: 'api' },
      ]
    end

    it 'lists the entries that match it, whatever their visibility' do
      expect(exposed_hosts.entries(group: 'api').map(&:host)).to eq(%w[api-internal.example.com api.example.com])
      expect(exposed_hosts.entries(group: :web).map(&:host)).to eq(%w[www.example.com])
    end

    it 'only lists the entries of the visibility that match it' do
      expect(exposed_hosts.entries(:private, group: 'api').map(&:host)).to eq(%w[api-internal.example.com])
      expect(exposed_hosts.entries(:public, group: :api).map(&:host)).to eq(%w[api.example.com])
    end

    it 'picks the first entry, of the visibility if any, that matches it' do
      expect(exposed_hosts.entry(group: 'api').host).to eq('api-internal.example.com')
      expect(exposed_hosts.entry(:public, group: 'api').host).to eq('api.example.com')
      expect(exposed_hosts.entry(:private, group: 'api').host).to eq('api-internal.example.com')
      expect(exposed_hosts.entry(:public, group: :api).host).to eq('api.example.com')
    end

    it 'names the metadata when no entry matches it' do
      expect { exposed_hosts.entries(group: 'unknown') }
        .to raise_error(KeyError, 'exposed_hosts: no host matching {group: "unknown"} is declared')
    end

    it 'names the visibility and the metadata when no entry of the visibility matches it' do
      expect { exposed_hosts.entry(:private, group: 'web') }
        .to raise_error(KeyError, 'exposed_hosts: no private host matching {group: "web"} is declared')
    end
  end

  context 'with an empty hosts list' do
    let(:entries) { [] }

    it 'declares no host' do
      expect(exposed_hosts.hosts).to be_empty
    end

    it 'has no entry to list' do
      expect { exposed_hosts.entries }.to raise_error(KeyError, 'exposed_hosts: no host is declared')
    end
  end

  describe 'validation' do
    let(:error) { described_class::Error }

    context 'without section for the environment' do
      let(:section) { nil }

      it { expect { exposed_hosts }.to raise_error(error, 'the environment section must be a hash, got nil') }
    end

    context 'with a section that is a list of hosts' do
      let(:section) { entries }

      it { expect { exposed_hosts }.to raise_error(error, /\Athe environment section must be a hash, got \[/) }
    end

    context 'without hosts' do
      let(:section) { {} }

      it { expect { exposed_hosts }.to raise_error(error, 'missing key: hosts') }
    end

    context 'with hosts that are not a list' do
      let(:section) { { hosts: nil } }

      it { expect { exposed_hosts }.to raise_error(error, 'hosts must be a list, got nil') }
    end

    context 'with other keys than hosts and default_url_options' do
      let(:section) { { host: 'www.example.com', main_domain: 'example.com' } }

      it { expect { exposed_hosts }.to raise_error(error, 'unknown keys: host, main_domain') }
    end

    context 'with default_url_options that are not a hash' do
      let(:section) { { hosts: entries, default_url_options: 'https' } }

      it { expect { exposed_hosts }.to raise_error(error, 'default_url_options: expected a hash without host, got "https"') }
    end

    context 'with default_url_options that set the host' do
      let(:section) { { hosts: entries, default_url_options: { host: 'www.example.com' } } }

      it { expect { exposed_hosts }.to raise_error(error, 'default_url_options: expected a hash without host, got {host: "www.example.com"}') }
    end

    {
      'an entry that is not a hash' => ['www.example.com', 'expected a hash, got "www.example.com"'],
      'a host with a port' => [{ host: 'www.example.com:80', visibility: 'public' }, 'host must not include a port, got "www.example.com:80"'],
      'default_url_options of an entry that set the host' => [
        { host: 'www.example.com', visibility: 'public', default_url_options: { host: 'other.example.com' } },
        'default_url_options must be a hash without host, got {host: "other.example.com"}',
      ],
    }.each do |description, (entry, message)|
      context "with #{description}" do
        let(:entries) { [{ host: 'private.example.com', visibility: 'private' }, entry] }

        it 'prefixes the message of the entry error with the position of the entry' do
          expect { exposed_hosts }.to raise_error(error, "hosts entry #2: #{message}") do |raised|
            expect(raised.cause).to be_a(GetaroundUtils::ExposedHosts::Entry::Error)
          end
        end
      end
    end
  end
end
