# frozen_string_literal: true

require 'spec_helper'
require 'rack'
require 'getaround_utils/exposed_hosts/configuration'
require 'getaround_utils/exposed_hosts/host_constraint'

RSpec.describe GetaroundUtils::ExposedHosts::HostConstraint do
  subject(:constraint) { described_class.new(entries) }

  let(:entries) do
    [
      GetaroundUtils::ExposedHosts::Entry.new(host: 'private.example.com', visibility: :private),
      GetaroundUtils::ExposedHosts::Entry.new(host: 'admin.example.com', visibility: :private),
    ]
  end

  def request_on(host, headers = {})
    Rack::Request.new(Rack::MockRequest.env_for('/', headers.merge('HTTP_HOST' => host)))
  end

  describe '.new' do
    it 'refuses an empty list, which could never match' do
      expect { described_class.new([]) }.to raise_error(ArgumentError, 'expected at least one entry, got []')
    end

    it 'refuses a list holding anything but entries' do
      expect { described_class.new([entries.first, 'www.example.com']) }
        .to raise_error(ArgumentError, /\Aexpected a list of entries, got \[#<GetaroundUtils::ExposedHosts::Entry:.*, "www\.example\.com"\]\z/)
    end

    it 'refuses the whole configuration' do
      configuration = GetaroundUtils::ExposedHosts::Configuration.new({ hosts: [{ host: 'www.example.com', visibility: 'public' }] })
      expect { described_class.new(configuration) }
        .to raise_error(ArgumentError, /\Aexpected a list of entries, got #<GetaroundUtils::ExposedHosts::Configuration:/)
    end

    it 'keeps its own copy of the list' do
      constraint
      entries.clear
      expect(constraint.matches?(request_on('private.example.com'))).to be(true)
    end
  end

  describe '#matches?' do
    %w[private.example.com admin.example.com ADMIN.Example.com:3000].each do |host|
      it "is true for #{host}" do
        expect(constraint.matches?(request_on(host))).to be(true)
      end
    end

    it 'is false for another host' do
      expect(constraint.matches?(request_on('www.example.com'))).to be(false)
    end

    it 'is false for another host forwarded for one of the entries' do
      forwarded = request_on('www.example.com', 'HTTP_X_FORWARDED_HOST' => 'private.example.com')
      expect(constraint.matches?(forwarded)).to be(false)
    end

    it 'is false without a Host header' do
      expect(constraint.matches?(Rack::Request.new(Rack::MockRequest.env_for('/')))).to be(false)
    end
  end
end
