# frozen_string_literal: true

module Api
  module V1
    # Orders Controller
    class OrdersController < ApplicationController
      include CartHelper

      before_action :set_cart
      before_action :set_order, only: %i[show cancel]
      after_action :invalidate_cache, only: %i[cancel]

      # rubocop:disable Metrics/MethodLength

      def cancel
        unless cancellable?(@order)
          return render_error(
            error: "Order cannot be cancelled", status: :bad_request,
            details: {
              message: "Order can only be cancelled if it is in a " \
                "pending state",
              order: {
                id: @order.id,
                status: @order.status
              },
              next_steps: "Issue a request for refund if the order is " \
                "already processed"
            }
          )
        end

        @order.update!(status: "cancelled")

        PaymentServiceNotifierJob.cancel_order(@order)

        render json: { message: "Order cancelled successfully" }, status: :ok
      end

      # rubocop:disable Metrics/AbcSize

      def index
        page = params[:page] || 1
        @orders = Order.where(user_id: @cart.user_id, app_id: @cart.app_id)
                       .by_status(params[:status])
                       .order(created_at: order_param)
                       .page(page).per(page_size)

        response = cache_collection(
          @orders,
          base_key, page:, page_size:,
                    filters: {
                      status: params[:status],
                      order: order_param
                    }
        ) do |collection|
          json_response(
            collection, message: "Orders retrieved successfully",
                        serializer:
          )
        end

        render json: response
      end

      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

      def show
        return unless stale?(
          @order, last_modified: @order.updated_at,
                  public: true
        )

        render json: json_response(
          @order, serializer:, message: "Order retrieved successfully"
        ), status: :ok
      end

      private

        def set_order
          @order = Order.find_by!(
            id: params[:id], user_id: @cart.user_id,
            app_id: @cart.app_id
          )
        end

        def set_cart
          @cart = cart
        end

        # Check if the order is eligible for cancellation
        def cancellable?(order)
          order.pending?
        end

        def serializer
          OrderSerializer
        end

        def order_param
          direction = params[:order] || "desc"

          if direction == "asc"
            :asc
          else
            :desc
          end
        end
    end
  end
end
