# frozen_string_literal: true

# app/controllers/api/v1/root_controller.rb
module API
  module V1
    # RootController is responsible for handling the root endpoint of the API.
    # It provides a welcome message and a list of available endpoints.
    #
    class RootController < ApplicationController
      skip_before_action :verify_authentication_credentials!

      # rubocop:disable Metrics/MethodLength

      # GET /api/v1
      #
      # This method is responsible for rendering a welcome message and a
      # list of available endpoints
      # in the Product Management Service API.
      #
      # ==== Returns
      #
      # JSON:
      # - message: Welcome message to the Product Management Service API
      # - version: API version
      # - documentation: Link to the API documentation
      # - available_endpoints: Hash containing the available endpoints
      #
      def index
        render json: {
          message: "Welcome to the Product Management Service API",
          version: "v1",
          base_url: "#{request.base_url}/api/v1",
          documentation: "https://documenter.getpostman.com/view/" \
          "14404907/2sAXjRWpnZ",
          available_endpoints: {
            products: "/api/v1/products",
            categories: "/api/v1/categories",
            carts: "/api/v1/cart",
            orders: "/api/v1/orders",
            status: "/api/v1/status"
          }
        }, status: :ok
      end

      # rubocop:enable Metrics/MethodLength
    end
  end
end
