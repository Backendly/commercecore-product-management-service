# frozen_string_literal: true

module API
  module V1
    # Checkout Controller
    class CheckoutController < ApplicationController
      include CartHelper

      before_action :set_cart

      # rubocop:disable Metrics/MethodLength

      # POST /api/v1/cart/checkout
      def create
        return unless no_pending_order?
        return unless valid_cart_items?

        @order = create_order

        PaymentServiceNotifierJob.perform_now(@order)

        move_cart_items_to_order(@order, @cart)

        render json: json_response(
          @order,
          message: "Order created successfully",
          serializer: OrderSerializer,
          extra_meta: {
            info: "Checkout in progress. Please complete the payment " \
            "to confirm the order"
          },
        ), status: :created
      end

      # rubocop:enable Metrics/MethodLength

      private

        def set_cart
          @cart = cart
        end

        def valid_cart_items?
          if @cart.nil? || @cart.cart_items.empty?
            render_error(
              error: "Cart is empty or does not exist",
              details: { errors: @cart.errors.full_messages,
                         cart_item_count: @cart.cart_items.count },
              status: :unprocessable_content,
            )
            return false
          end
          true
        end

        # rubocop:disable Metrics/MethodLength

        # Checks if the user has any pending orders associated with the
        # current cart.
        #
        # If a pending order exists, it renders an error response with a message
        # and next steps for the user. Returns true if no pending orders
        # are found.
        #
        # === Returns:
        # * Boolean: Returns false if a pending order exists;
        #   otherwise, returns true.
        #
        # === Examples:
        #   no_pending_order? # => false if there is a pending order
        #   for the user
        #
        def no_pending_order?
          # let's verify there are no pending or processing orders
          order = Order.where(
            user_id: @cart.user_id,
            app_id: @cart.app_id,
            status: %w[pending processing],
          ).first

          if order
            render_error(
              error: "You already have an order in a #{order.status} state",
              status: :payment_required,
              details: {
                order_id: order.id,
                next_steps: "Please complete the payment to confirm the order",
                alternative: "You can cancel the #{order.status} order and " \
                "create a new one"
              },
            )

            return false
          end

          true
        end

        # rubocop:enable Metrics/MethodLength

        def create_order
          Order.create!(
            user_id: @cart.user_id,
            developer_id: @cart.developer_id,
            app_id: @cart.app_id,
            total_amount: calculate_total_amount(@cart),
            status: "pending",
          )
        end

        def move_cart_items_to_order(order, cart)
          cart.cart_items.each do |cart_item|
            order.order_items.create!(
              product_id: cart_item.product_id,
              quantity: cart_item.quantity,
              price_at_purchase: cart_item.product.price,
            )
          end
        end

        # Helper: Calculate the total amount for the order
        def calculate_total_amount(cart)
          cart.cart_items.sum { |item| item.quantity * item.product.price }
        end
    end
  end
end
