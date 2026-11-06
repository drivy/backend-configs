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
        { host: 'admin.example.com', visibility: 'private', group: 'backoffice' },
        { host: 'api-internal.example.com', visibility: 'private', group: 'api' },
        { host: 'www.example.com', visibility: 'public', group: 'web' },
        { host: 'api.example.com', visibility: 'public', group: 'api' },
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

    it 'serves the route on another host forwarded for a public host matching it' do
      post 'http://other.example.com/api', headers: { 'X-Forwarded-Host' => 'api.example.com' }
      expect(response).to have_http_status(:ok)
    end

    it 'does not serve the route on a public host matching it forwarded for another host' do
      post 'http://api.example.com/api', headers: { 'X-Forwarded-Host' => 'other.example.com' }
      expect(response).to have_http_status(:not_found)
    end

    it 'leaves params[:host] to the request' do
      post 'http://api.example.com/api?host=other.example.com'
      expect(response.parsed_body['host']).to eq('other.example.com')
    end

    context 'with a visibility' do
      it 'serves the route on the hosts of the visibility only' do
        expect(served_hosts(draw_constrained_route(:private))).to eq(%w[admin.example.com api-internal.example.com])
      end
    end

    context 'with a visibility and metadata' do
      it 'serves the route on the hosts of the visibility whose entry matches the metadata only' do
        expect(served_hosts(draw_constrained_route(:public, group: :api))).to eq(%w[api.example.com])
      end
    end

    context 'without visibility, with metadata' do
      it 'serves the route on every declared host whose entry matches the metadata' do
        expect(served_hosts(draw_constrained_route(group: 'api'))).to eq(%w[api-internal.example.com api.example.com])
      end
    end

    context 'without visibility nor metadata' do
      it 'serves the route on every declared host' do
        expect(served_hosts(draw_constrained_route)).to eq(entries.pluck(:host))
      end
    end

    context 'without matching entry' do
      it 'fails to draw the routes' do
        expect { draw_constrained_route(:private, group: 'web') }.to raise_error(
          GetaroundUtils::ExposedHosts::UndeclaredHost,
          'no private host matching {group: "web"} is declared',
        )
      end
    end

    it 'generates the URLs on one of its hosts when combined with host_defaults' do
      route_set = draw_routes_with(entries) do
        host_constraints(group: 'api') do
          host_defaults(:public, group: 'api') do
            get '/constrained', to: ->(_env) { [200, {}, []] }, as: :constrained
          end
        end
      end
      expect(served_hosts(route_set)).to eq(%w[api-internal.example.com api.example.com])
      expect(route_set.url_helpers.constrained_url).to eq('http://api.example.com/constrained')
    end

    it 'leaves the host of the URLs to the default URL options' do
      route_set = draw_constrained_route(:private)
      route_set.default_url_options = { host: 'www.example.com' }
      expect(route_set.url_helpers.constrained_url).to eq('http://www.example.com/constrained')
    end
  end

  describe '#private_routes' do
    %w[private.example.com admin.example.com PRIVATE.Example.com:3000].each do |host|
      it "serves the route on #{host}" do
        get "http://#{host}/private"
        expect(response).to have_http_status(:ok)
      end
    end

    it 'does not serve the route on a public host' do
      get 'http://www.example.com/private'
      expect(response).to have_http_status(:not_found)
    end

    it 'does not serve the route on a public host forwarded for a private one' do
      get 'http://www.example.com/private', headers: { 'X-Forwarded-Host' => 'private.example.com' }
      expect(response).to have_http_status(:not_found)
    end

    it 'generates the URLs on the first private host' do
      expect(url_helpers.private_page_url).to eq('http://private.example.com/private')
    end

    it 'sets params[:host] to the declared host, whatever the host or the query string of the request says' do
      # admin.example.com is a private host, but not the first one, to which private_routes sets params[:host].
      get 'http://admin.example.com/private?host=evil.example.com'
      expect(response.parsed_body['host']).to eq(Rails.application.config.exposed_hosts.entry(:private).host)
    end

    context 'with metadata, given as a Symbol' do
      it 'serves the route on the private hosts matching it' do
        get 'http://admin.example.com/admin'
        expect(response).to have_http_status(:ok)
      end

      it 'does not serve the route on the other private hosts' do
        get 'http://private.example.com/admin'
        expect(response).to have_http_status(:not_found)
      end

      it 'generates the URLs on the first private host matching it' do
        expect(url_helpers.admin_page_url).to eq('http://admin.example.com/admin')
      end
    end

    context 'without private entry' do
      it 'fails to draw the routes' do
        expect {
          draw_routes_with([{ host: 'www.example.com', visibility: 'public' }]) do
            private_routes { get '/private', to: ->(_env) { [200, {}, []] } }
          end
        }.to raise_error(GetaroundUtils::ExposedHosts::UndeclaredHost, 'no private host is declared')
      end
    end

    context 'with a visibility among the criteria' do
      it 'fails to draw the routes' do
        expect {
          draw_routes_with([{ host: 'www.example.com', visibility: 'public' }]) do
            private_routes(visibility: :public) { get '/private', to: ->(_env) { [200, {}, []] } }
          end
        }.to raise_error(ArgumentError, 'visibility must be given once, got :private and visibility: :public')
      end
    end
  end

  describe '#host_defaults' do
    %w[www.example.com private.example.com].each do |host|
      it "serves the route on #{host}" do
        get "http://#{host}/public"
        expect(response).to have_http_status(:ok)
      end
    end

    it 'generates the URLs on the first host of the visibility' do
      expect(url_helpers.public_page_url).to eq('http://www.example.com/public')
    end

    it 'leaves the other URL options to the default URL options of the routes' do
      route_set = draw_routes_with([{ host: 'www.example.com', visibility: 'public' }]) do
        host_defaults(:public) { get '/public', to: ->(_env) { [200, {}, []] }, as: :public }
      end
      route_set.default_url_options = { protocol: 'https', host: 'other.example.com', port: 3000 }
      expect(route_set.url_helpers.public_url).to eq('https://www.example.com:3000/public')
    end

    it 'sets params[:host] to the declared host, whatever the host or the query string of the request says' do
      get 'http://private.example.com/public?host=evil.example.com'
      expect(response.parsed_body['host']).to eq('www.example.com')
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

      it 'generates the URLs on the first host of the visibility matching it' do
        route_set = draw_routes_with(entries) do
          host_defaults(:public, group: 'api') { get '/status', to: ->(_env) { [200, {}, []] }, as: :status }
        end
        expect(route_set.url_helpers.status_url).to eq('http://api.example.com/status')
      end
    end

    context 'without entry of the visibility' do
      it 'fails to draw the routes' do
        expect {
          draw_routes_with([{ host: 'private.example.com', visibility: 'private' }]) do
            host_defaults(:public) { get '/public', to: ->(_env) { [200, {}, []] } }
          end
        }.to raise_error(GetaroundUtils::ExposedHosts::UndeclaredHost, 'no public host is declared')
      end
    end
  end
end
