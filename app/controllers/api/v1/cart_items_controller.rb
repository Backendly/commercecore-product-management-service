# frozen_string_literal: true

module Api
  module V1
    # Controller for the cart item resource.
    class CartItemsController < ApplicationController
      include CartHelper
      before_action :set_cart, only: %i[create index]
      before_action :valid_product?, only: %i[create]
      before_action :set_cart_item, only: %i[destroy show]

      # rubocop:disable Metrics/MethodLength

      # GET /api/v1/cart/items
      def create
        @cart_item, is_new_record = @cart.add_or_update_item(cart_item_params)

        if @cart_item.persisted? && @cart_item.errors.empty?
          message = if is_new_record
                      'Cart item created successfully'
                    else
                      'Cart item updated successfully'
                    end
          status = is_new_record ? :created : :ok
          render json: json_response(
            @cart_item, serializer: CartItemSerializer,
                        message:, status:
          ), status:
        else
          render_error(status: :unprocessable_entity,
                       details: @cart_item.errors)
        end
      end

      # rubocop:enable Metrics/MethodLength

      # DELETE /api/v1/cart/items/:id
      def destroy
        @cart_item.destroy!
        head :no_content
      end

      # GET /api/v1/cart/items/:id
      def show
        render json: json_response(@cart_item, serializer:)
      end

      # GET /api/v1/cart/items
      def index
        render json: json_response(
          @cart.cart_items,
          serializer:, message: 'Cart items retrieved successfully'
        )
      end

      private

        def set_cart
          @cart = cart
        end

        def cart_item_params
          params.require(:cart_item).permit(:product_id, :quantity)
        end

        def serializer
          CartItemSerializer
        end

        # rubocop:disable Metrics/MethodLength

        # Validates the presence and association of a product for a cart item.
        # It checks if the product ID is provided, if the product exists,
        # and if it is associated with the correct app. Returns false if
        # any validation fails and renders an error response.
        #
        #
        # === Returns:
        # * (Boolean) Returns false if validation fails; otherwise, returns
        #   +nil+.
        #
        #
        # === Examples:
        #   valid_product? # => false if product_id is nil or invalid
        def valid_product?
          if cart_item_params[:product_id].nil?
            render_error(status: :unprocessable_content,
                         details: { product_id: 'must be provided' })
            return false
          end

          product = cache_resource("product_#{cart_item_params[:product_id]}",
                                   expires_in: 10.minutes) do
            Product.find_by(id: cart_item_params[:product_id])
          end

          if product.nil?
            render_error(status: :unprocessable_content,
                         details: { product: 'must exist' })
            return false
          end

          if product.app_id != @cart.app_id
            render_error(
              status: :unprocessable_content,
              details: {
                product: 'must be associated with the app'
              }
            )
            return false
          end

          if product.stock_quantity < cart_item_params[:quantity].to_i
            render_error(
              error: 'Invalid quantity',
              status: :unprocessable_content, details: {
                quantity: 'must be less than or equal to the stock',
                stock_quantity: product.stock_quantity
              }
            )
            return false
          end

          true
        end

        # rubocop:enable Metrics/MethodLength

        def set_cart_item
          set_cart.tap { Rails.logger.debug "Cart: #{@cart}" }

          @cart_item = cache_resource(current_cache_key) do
            CartItem.find_by!(id: params[:id], cart_id: @cart&.id)
          end
        end
    end
  end
end
