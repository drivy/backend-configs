# frozen_string_literal: true

require 'rails_helper'

# Runs against the routes of the spec DummyApplication: see spec/dummy/config/routes.rb.
RSpec.describe GetaroundUtils::ExposedHosts::RoutingHelpers, type: :request do
  let(:url_helpers) { Rails.application.routes.url_helpers }

  # Draws a new route set against another section than that of the dummy application.
  def draw_routes_with(entries, &)
    original = Rails.application.config.exposed_hosts
    Rails.application.config.exposed_hosts = GetaroundUtils::ExposedHosts::Configuration.new({ hosts: entries })
    ActionDispatch::Routing::RouteSet.new.tap { |route_set| route_set.draw(&) }
  ensure
    Rails.application.config.exposed_hosts = original
  end

  describe '#host_constraints' do
    let(:entries) do
      [
        { host: 'admin.example.com', exposure: 'internal', group: 'backoffice' },
        { host: 'api-internal.example.com', exposure: 'internal', group: 'api' },
        { host: 'www.example.com', exposure: 'external', group: 'web' },
        { host: 'api.example.com', exposure: 'external', group: 'api' },
      ]
    end

    def draw_constrained_route(*, **)
      draw_routes_with(entries) do
        host_constraints(*, **) { get '/constrained', to: ->(_env) { [200, {}, []] }, as: :constrained }
      end
    end

    # The hosts, declared or not, on which the route set serves the constrained route.
    def served_hosts(route_set)
      [*entries.pluck(:host), 'undeclared.example.com'].select do |host|
        Rack::MockRequest.new(route_set).get('/constrained', 'HTTP_HOST' => host).status == 200
      end
    end

    it 'serves the route on the hosts matching it' do
      post 'http://api.example.com/api'
      expect(response).to have_http_status(:ok)
    end

    it 'does not serve the route on the other hosts' do
      post 'http://www.example.com/api'
      expect(response).to have_http_status(:not_found)
    end

    it 'serves the route on another host forwarded for an external host matching it' do
      post 'http://other.example.com/api', headers: { 'X-Forwarded-Host' => 'api.example.com' }
      expect(response).to have_http_status(:ok)
    end

    it 'does not serve the route on an external host matching it forwarded for another host' do
      post 'http://api.example.com/api', headers: { 'X-Forwarded-Host' => 'other.example.com' }
      expect(response).to have_http_status(:not_found)
    end

    it 'leaves params[:host] to the request' do
      post 'http://api.example.com/api?host=other.example.com'
      expect(response.parsed_body['host']).to eq('other.example.com')
    end

    context 'with an exposure' do
      it 'serves the route on the hosts of the exposure only' do
        expect(served_hosts(draw_constrained_route(:internal))).to eq(%w[admin.example.com api-internal.example.com])
      end
    end

    context 'with an exposure and metadata' do
      it 'serves the route on the hosts of the exposure whose entry matches the metadata only' do
        expect(served_hosts(draw_constrained_route(:external, group: :api))).to eq(%w[api.example.com])
      end
    end

    context 'without exposure, with metadata' do
      it 'serves the route on every declared host whose entry matches the metadata' do
        expect(served_hosts(draw_constrained_route(group: 'api'))).to eq(%w[api-internal.example.com api.example.com])
      end
    end

    context 'without exposure nor metadata' do
      it 'serves the route on every declared host' do
        expect(served_hosts(draw_constrained_route)).to eq(entries.pluck(:host))
      end
    end

    context 'without matching entry' do
      it 'fails to draw the routes' do
        expect { draw_constrained_route(:internal, group: 'web') }.to raise_error(
          GetaroundUtils::ExposedHosts::UndeclaredHost,
          'no internal host matching {group: "web"} is declared',
        )
      end
    end

    it 'generates the URLs on one of its hosts when combined with host_defaults' do
      route_set = draw_routes_with(entries) do
        host_constraints(group: 'api') do
          host_defaults(:external, group: 'api') do
            get '/constrained', to: ->(_env) { [200, {}, []] }, as: :constrained
          end
        end
      end
      expect(served_hosts(route_set)).to eq(%w[api-internal.example.com api.example.com])
      expect(route_set.url_helpers.constrained_url).to eq('http://api.example.com/constrained')
    end

    it 'leaves the host of the URLs to the default URL options' do
      route_set = draw_constrained_route(:internal)
      route_set.default_url_options = { host: 'www.example.com' }
      expect(route_set.url_helpers.constrained_url).to eq('http://www.example.com/constrained')
    end
  end

  describe '#internal_routes' do
    %w[internal.example.com admin.example.com INTERNAL.Example.com:3000].each do |host|
      it "serves the route on #{host}" do
        get "http://#{host}/internal"
        expect(response).to have_http_status(:ok)
      end
    end

    it 'does not serve the route on an external host' do
      get 'http://www.example.com/internal'
      expect(response).to have_http_status(:not_found)
    end

    it 'does not serve the route on an external host forwarded for an internal one' do
      get 'http://www.example.com/internal', headers: { 'X-Forwarded-Host' => 'internal.example.com' }
      expect(response).to have_http_status(:not_found)
    end

    it 'generates the URLs on the first internal host' do
      expect(url_helpers.internal_page_url).to eq('http://internal.example.com/internal')
    end

    it 'sets params[:host] to the declared host, whatever the host or the query string of the request says' do
      # admin.example.com is an internal host, but not the first one, to which internal_routes sets params[:host].
      get 'http://admin.example.com/internal?host=evil.example.com'
      expect(response.parsed_body['host']).to eq(Rails.application.config.exposed_hosts.entry(:internal).host)
    end

    context 'with metadata, given as a Symbol' do
      it 'serves the route on the internal hosts matching it' do
        get 'http://admin.example.com/admin'
        expect(response).to have_http_status(:ok)
      end

      it 'does not serve the route on the other internal hosts' do
        get 'http://internal.example.com/admin'
        expect(response).to have_http_status(:not_found)
      end

      it 'generates the URLs on the first internal host matching it' do
        expect(url_helpers.admin_page_url).to eq('http://admin.example.com/admin')
      end
    end

    context 'without internal entry' do
      it 'fails to draw the routes' do
        expect {
          draw_routes_with([{ host: 'www.example.com', exposure: 'external' }]) do
            internal_routes { get '/internal', to: ->(_env) { [200, {}, []] } }
          end
        }.to raise_error(GetaroundUtils::ExposedHosts::UndeclaredHost, 'no internal host is declared')
      end
    end

    context 'with an exposure among the criteria' do
      it 'fails to draw the routes' do
        expect {
          draw_routes_with([{ host: 'www.example.com', exposure: 'external' }]) do
            internal_routes(exposure: :external) { get '/internal', to: ->(_env) { [200, {}, []] } }
          end
        }.to raise_error(ArgumentError, 'exposure must be given once, got :internal and exposure: :external')
      end
    end
  end

  describe '#host_defaults' do
    %w[www.example.com internal.example.com].each do |host|
      it "serves the route on #{host}" do
        get "http://#{host}/external"
        expect(response).to have_http_status(:ok)
      end
    end

    it 'generates the URLs on the first host of the exposure' do
      expect(url_helpers.external_page_url).to eq('http://www.example.com/external')
    end

    it 'leaves the other URL options to the default URL options of the routes' do
      route_set = draw_routes_with([{ host: 'www.example.com', exposure: 'external' }]) do
        host_defaults(:external) { get '/external', to: ->(_env) { [200, {}, []] }, as: :external }
      end
      route_set.default_url_options = { protocol: 'https', host: 'other.example.com', port: 3000 }
      expect(route_set.url_helpers.external_url).to eq('https://www.example.com:3000/external')
    end

    it 'sets params[:host] to the declared host, whatever the host or the query string of the request says' do
      get 'http://internal.example.com/external?host=evil.example.com'
      expect(response.parsed_body['host']).to eq('www.example.com')
    end

    context 'with metadata' do
      let(:entries) do
        [
          { host: 'admin.example.com', exposure: 'internal', group: 'backoffice' },
          { host: 'api-internal.example.com', exposure: 'internal', group: 'api' },
          { host: 'www.example.com', exposure: 'external', group: 'web' },
          { host: 'api.example.com', exposure: 'external', group: 'api' },
        ]
      end

      it 'generates the URLs on the first host of the exposure matching it' do
        route_set = draw_routes_with(entries) do
          host_defaults(:external, group: 'api') { get '/status', to: ->(_env) { [200, {}, []] }, as: :status }
        end
        expect(route_set.url_helpers.status_url).to eq('http://api.example.com/status')
      end
    end

    context 'without entry of the exposure' do
      it 'fails to draw the routes' do
        expect {
          draw_routes_with([{ host: 'internal.example.com', exposure: 'internal' }]) do
            host_defaults(:external) { get '/external', to: ->(_env) { [200, {}, []] } }
          end
        }.to raise_error(GetaroundUtils::ExposedHosts::UndeclaredHost, 'no external host is declared')
      end
    end
  end
end
