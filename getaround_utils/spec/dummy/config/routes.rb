# frozen_string_literal: true

Rails.application.routes.draw do
  default_url_options(host: Rails.configuration.exposed_hosts.entry(:public).host)

  root to: 'links#show'

  private_routes(group: :internal) do
    get '/admin', to: 'links#show', as: :admin_page
  end

  private_routes do
    get '/private', to: 'links#show', as: :private_page
  end

  host_defaults(:public) do
    get '/public', to: 'links#show', as: :public_page
  end

  host_constraints(group: :api) do
    post '/api', to: 'links#show', as: :api

    host_defaults(:public, group: :api) do
      post '/graphql', to: 'links#show', as: :graphql
    end
  end
end
