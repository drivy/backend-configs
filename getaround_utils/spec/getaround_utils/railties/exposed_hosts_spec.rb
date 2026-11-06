# frozen_string_literal: true

require 'rails_helper'

# The spec DummyApplication loads the railtie, with a configuration this spec shares with the routing specs:
# see spec/dummy/config.
RSpec.describe GetaroundUtils::Railties::ExposedHosts do
  let(:config) { Rails.application.config }

  it 'loads the entries of the environment, evaluating the ERB with the ENV set before the application class' do
    expect(config.exposed_hosts.entries.map(&:to_h)).to eq([
      { host: 'private.example.com', visibility: :private },
      { host: 'admin.example.com', visibility: :private, group: 'internal', port: 42 },
      { host: 'www.example.com', visibility: :public },
      { host: 'api.example.com', visibility: :public, group: :api },
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
