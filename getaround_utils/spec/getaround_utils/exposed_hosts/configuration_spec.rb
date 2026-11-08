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
    context 'without visibility nor metadata' do
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
      end
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

      it 'freezes the list' do
        expect(exposed_hosts.entries(:public)).to be_frozen
      end
    end

    context 'with a visibility given as a String' do
      it { expect(exposed_hosts.entries('private')).to eq(exposed_hosts.entries(:private)) }
    end

    context 'with an unknown visibility' do
      it { expect { exposed_hosts.entries(:internal) }.to raise_error(ArgumentError, 'visibility must be public or private, got :internal') }
    end

    context 'with a visibility given as a keyword' do
      it 'takes it as a Symbol or a String' do
        expect(exposed_hosts.entries(visibility: :public)).to eq(exposed_hosts.entries(:public))
        expect(exposed_hosts.entries(visibility: 'public')).to eq(exposed_hosts.entries(:public))
      end

      it 'refuses an unknown visibility' do
        expect { exposed_hosts.entries(visibility: :internal) }
          .to raise_error(ArgumentError, 'visibility must be public or private, got :internal')
      end
    end

    context 'with a visibility given both as an argument and as a keyword' do
      it 'refuses it, even when both are the same' do
        expect { exposed_hosts.entries(:private, visibility: :private) }
          .to raise_error(ArgumentError, 'visibility must be given once, got :private and visibility: :private')
      end
    end

    context 'without entry of the visibility' do
      let(:entries) { [{ host: 'private.example.com', visibility: 'private' }] }

      it 'names the visibility' do
        expect { exposed_hosts.entries(:public) }
          .to raise_error(GetaroundUtils::ExposedHosts::UndeclaredHost, 'no public host is declared')
      end
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
    it 'is the first entry of the visibility' do
      expect(exposed_hosts.entry(:public).to_h).to eq(host: 'www.example.com', visibility: :public, port: 3000)
      expect(exposed_hosts.entry(:private).to_h).to eq(host: 'private.example.com', visibility: :private, group: 'internal')
    end

    context 'without visibility' do
      it { expect { exposed_hosts.entry }.to raise_error(ArgumentError, 'wrong number of arguments (given 0, expected 1)') }
    end

    context 'with a visibility given as a String' do
      it { expect(exposed_hosts.entry('public')).to eq(exposed_hosts.entry(:public)) }
    end

    context 'with an unknown visibility' do
      it { expect { exposed_hosts.entry(:internal) }.to raise_error(ArgumentError, 'visibility must be public or private, got :internal') }
    end

    context 'with a visibility given both as an argument and as a keyword' do
      it { expect { exposed_hosts.entry(:public, visibility: :private) }.to raise_error(ArgumentError, 'visibility must be given once, got :public and visibility: :private') }
    end

    context 'without entry of the visibility' do
      let(:entries) { [{ host: 'private.example.com', visibility: 'private' }] }

      it 'names the visibility' do
        expect { exposed_hosts.entry(:public) }
          .to raise_error(GetaroundUtils::ExposedHosts::UndeclaredHost, 'no public host is declared')
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

    it 'fails to list the entries when none matches it' do
      expect { exposed_hosts.entries(group: 'unknown') }.to raise_error(
        GetaroundUtils::ExposedHosts::UndeclaredHost,
        'no host matching {group: "unknown"} is declared',
      )
    end

    it 'fails to list the entries of the visibility when none matches it' do
      expect { exposed_hosts.entries(:public, group: 'backoffice') }.to raise_error(
        GetaroundUtils::ExposedHosts::UndeclaredHost,
        'no public host matching {group: "backoffice"} is declared',
      )
    end

    it 'picks the first entry of the visibility that matches it' do
      expect(exposed_hosts.entry(:public, group: 'api').host).to eq('api.example.com')
      expect(exposed_hosts.entry(:private, group: :api).host).to eq('api-internal.example.com')
    end

    it 'fails to pick an entry of the visibility when none matches it' do
      expect { exposed_hosts.entry(:private, group: 'web') }.to raise_error(
        GetaroundUtils::ExposedHosts::UndeclaredHost,
        'no private host matching {group: "web"} is declared',
      )
    end
  end

  context 'with an empty hosts list' do
    let(:entries) { [] }

    it 'declares no host' do
      expect(exposed_hosts.hosts).to be_empty
    end

    it 'fails to list the entries' do
      expect { exposed_hosts.entries }.to raise_error(GetaroundUtils::ExposedHosts::UndeclaredHost, 'no host is declared')
    end

    it 'fails to pick an entry' do
      expect { exposed_hosts.entry(:public) }.to raise_error(GetaroundUtils::ExposedHosts::UndeclaredHost, 'no public host is declared')
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

    context 'with other keys than hosts' do
      let(:section) { { host: 'www.example.com', main_domain: 'example.com' } }

      it { expect { exposed_hosts }.to raise_error(error, 'unknown keys: host, main_domain') }
    end

    {
      'an entry that is not a hash' => ['www.example.com', 'expected a hash, got "www.example.com"'],
      'a host with a port' => [{ host: 'www.example.com:80', visibility: 'public' }, 'host must not include a port, got "www.example.com:80"'],
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
