# frozen_string_literal: true

Rails.application.routes.draw do
  default_url_options(**Rails.application.config.exposed_hosts.entry(:public).url_options)

  root to: 'links#show'

  private_routes(group: :internal) do
    get '/admin', to: 'links#show', as: :admin_page
  end

  private_routes do
    get '/private', to: 'links#show', as: :private_page
  end

  default_host(:public) do
    get '/public', to: 'links#show', as: :public_page
  end

  host_constraint(group: :api) do
    post '/api', to: 'links#show', as: :api

    default_host(:public, group: :api) do
      post '/graphql', to: 'links#show', as: :graphql
    end
  end
end
