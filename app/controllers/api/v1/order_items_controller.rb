# frozen_string_literal: true

module Api
  module V1
    # Order Items Controller
    class OrderItemsController < ApplicationController
      before_action :set_order, only: %i[index show]
      before_action :set_order_item, only: %i[show]

      def index
        page = params[:page] || 1

        @order_items = OrderItem.where(order_id: @order.id)
                         .page(page).per(page_size)

        render json: json_response(
          @order_items, message: 'Order items retrieved successfully',
          serializer: OrderItemSerializer
        ), status: :ok
      end

      def show
        return unless stale?(
          @order_item,
          last_modified: @order_item.updated_at, public: true
        )

        render json: json_response(
          @order_item, message: 'Order item retrieved successfully',
          serializer: OrderItemSerializer
        ), status: :ok
      end

      private

        def set_order_item
          @order_item = OrderItem.find_by!(
            id: params[:id],
            order_id: @order.id
          )
        end

        def set_order
          @order = Order.find_by!(id: params[:order_id], user_id:, app_id:)
        end
    end
  end
end
