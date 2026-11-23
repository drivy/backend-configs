# frozen_string_literal: true

# Renders params[:host] and the URL of every named route, as a controller generates them during the request.
class LinksController < ActionController::API
  def show
    render json: {
      host: params[:host],
      urls: {
        external_page: external_page_url,
        internal_page: internal_page_url,
        admin_page: admin_page_url,
        api: api_url,
        graphql: graphql_url,
      },
    }
  end
end
