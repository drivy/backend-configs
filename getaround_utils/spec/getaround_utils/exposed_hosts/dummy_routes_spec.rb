# frozen_string_literal: true

require 'rails_helper'

# Shows where the routing helpers point the URLs they generate, on the routes of the spec DummyApplication: see
# spec/dummy/config/routes.rb. Each of its routes renders the URLs that LinksController generates during the request.
RSpec.describe 'Routes of the dummy application', type: :request do
  def urls
    response.parsed_body['urls']
  end

  context 'when generated on the API host' do
    before { post 'http://api.example.com/api' }

    it 'generates the URLs of host_defaults and private_routes on the host of their entry' do
      expect(urls).to include(
        'public_page' => 'http://www.example.com/public',
        'private_page' => 'http://private.example.com/private',
        'admin_page' => 'http://admin.example.com/admin',
      )
    end

    it 'generates the URL of host_constraints alone on the host of the request, which answers here' do
      expect(urls['api']).to eq('http://api.example.com/api')
      post urls['api']
      expect(response).to have_http_status(:ok)
    end

    it 'generates the URL of host_constraints wrapped in host_defaults on the host of its entry' do
      expect(urls['graphql']).to eq('http://api.example.com/graphql')
    end
  end

  context 'when generated on the admin host' do
    before { get 'http://admin.example.com/admin' }

    it 'generates the URL of host_defaults on the public host' do
      expect(urls['public_page']).to eq('http://www.example.com/public')
    end

    it 'generates the URL of host_constraints alone on the admin host, where the route does not answer' do
      expect(urls['api']).to eq('http://admin.example.com/api')
      post urls['api']
      expect(response).to have_http_status(:not_found)
    end

    it 'generates the URL of host_constraints wrapped in host_defaults on its own host, where the route answers' do
      expect(urls['graphql']).to eq('http://api.example.com/graphql')
      post urls['graphql']
      expect(response).to have_http_status(:ok)
    end
  end

  context 'when generated outside a request' do
    let(:url_helpers) { Rails.application.routes.url_helpers }

    it 'generates the URLs of host_defaults and private_routes on the host of their entry' do
      expect(url_helpers.public_page_url).to eq('http://www.example.com/public')
      expect(url_helpers.private_page_url).to eq('http://private.example.com/private')
      expect(url_helpers.admin_page_url).to eq('http://admin.example.com/admin')
    end

    it 'generates the URL of host_constraints alone on the default host of the routes, where the route does not answer' do
      expect(url_helpers.api_url).to eq('http://www.example.com/api')
      post url_helpers.api_url
      expect(response).to have_http_status(:not_found)
    end

    it 'generates the URL of host_constraints wrapped in host_defaults on its own host, where the route answers' do
      expect(url_helpers.graphql_url).to eq('http://api.example.com/graphql')
      post url_helpers.graphql_url
      expect(response).to have_http_status(:ok)
    end
  end
end
