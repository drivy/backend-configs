# frozen_string_literal: true

Rails.application.routes.draw do
  default_url_options(host: Rails.configuration.exposed_hosts.entry(:external).host)

  root to: 'links#show'

  internal_routes(group: :backoffice) do
    get '/admin', to: 'links#show', as: :admin_page
  end

  internal_routes do
    get '/internal', to: 'links#show', as: :internal_page
  end

  host_defaults(:external) do
    get '/external', to: 'links#show', as: :external_page
  end

  host_constraints(group: :api) do
    post '/api', to: 'links#show', as: :api

    host_defaults(:external, group: :api) do
      post '/graphql', to: 'links#show', as: :graphql
    end
  end
end
