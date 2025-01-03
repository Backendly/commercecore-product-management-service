# frozen_string_literal: true

module API
  module V1
    # Controller for the cart resource.
    class CartsController < ApplicationController
      include CartHelper

      # GET /api/v1/cart
      #
      # Retrieve the current user's cart.
      def show
        return unless stale?(last_modified: cart.updated_at, public: true)

        render json: json_response(
          cart, serializer:, message: "Cart retrieved successfully",
        )
      end

      private

        def serializer
          CartSerializer
        end
    end
  end
end
