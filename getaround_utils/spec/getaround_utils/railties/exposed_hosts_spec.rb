# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GetaroundUtils::Railties::ExposedHosts do
  let(:config) { Rails.application.config }

  it 'loads the entries of the environment, evaluating the ERB with the ENV set before the application class' do
    expect(config.exposed_hosts.entries.map(&:to_h)).to eq([
      { host: 'private.example.com', visibility: :private },
      { host: 'admin.example.com', visibility: :private, group: 'internal' },
      { host: 'www.example.com', visibility: :public },
      { host: 'api.example.com', visibility: :public, group: 'api' },
    ])
  end

  it 'merges the default_url_options of each entry over those of the environment' do
    expect(config.exposed_hosts.entries.map(&:url_options)).to eq([
      { port: 3000, host: 'private.example.com' },
      { port: 3001, host: 'admin.example.com' },
      { port: 3000, host: 'www.example.com' },
      { port: 3000, host: 'api.example.com' },
    ])
  end

  it 'loads them before the environment files' do
    expect(config.x.private_host).to eq('private.example.com')
    expect(config.x.public_host).to eq('www.example.com')
  end

  it 'leaves config.hosts to the application, which starts empty in test' do
    expect(config.hosts).to be_empty
  end
end
