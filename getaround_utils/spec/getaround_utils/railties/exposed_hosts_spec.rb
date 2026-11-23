# frozen_string_literal: true

require 'rails_helper'

# The spec DummyApplication loads the railtie, with a configuration this spec shares with the routing specs:
# see spec/dummy/config.
RSpec.describe GetaroundUtils::Railties::ExposedHosts do
  let(:config) { Rails.application.config }

  it 'loads the entries of the environment, evaluating the ERB with the ENV set before the application class' do
    expect(config.exposed_hosts.entries.map(&:to_h)).to eq([
      { host: 'internal.example.com', exposure: :internal },
      { host: 'admin.example.com', exposure: :internal, group: 'backoffice', port: 42 },
      { host: 'www.example.com', exposure: :external },
      { host: 'api.example.com', exposure: :external, group: :api },
    ])
  end

  it 'loads them before the environment files' do
    expect(config.x.internal_host).to eq('internal.example.com')
    expect(config.x.external_host).to eq('www.example.com')
  end

  it 'leaves config.hosts to the application, which starts empty in test' do
    expect(config.hosts).to be_empty
  end
end
