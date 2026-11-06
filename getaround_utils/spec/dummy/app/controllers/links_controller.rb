# frozen_string_literal: true

class LinksController < ActionController::API
  def show
    render json: {
      host: params[:host],
      urls: {
        public_page: public_page_url,
        private_page: private_page_url,
        admin_page: admin_page_url,
        api: api_url,
        graphql: graphql_url,
      },
    }
  end
end
