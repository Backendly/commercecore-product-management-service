# frozen_string_literal: true

# Payment status job
class PaymentStatusJob < ApplicationJob
  queue_as :high_priority

  # rubocop:disable Metrics/MethodLength

  def perform(order_id, status)
    order = Order.find_by(id: order_id)

    unless order
      Rails.logger.error("Order with ID #{order_id} not found")
      return
    end

    status_actions = {
      succeeded: ['successful', true],
      created: ['processing', false],
      failed: ['failed', false],
      refunded: ['refunded', true]
    }

    sym_status = status.to_sym

    if status_actions.key?(sym_status)
      new_status, update_stock = status_actions[sym_status]
      update_order_and_notify(order.id, new_status)

      if update_stock
        UpdateProductStockJob.perform_later(order.id, status: new_status)
      end

      ClearCartJob.perform_later(order.user_id) if status == 'succeeded'
    else
      Rails.logger.error "Invalid status: #{status}"
      return
    end

    OrderStatusNotificationJob.notify(order)
  end

  private

    def update_order_and_notify(order_id, status)
      UpdateOrderStatusJob.perform_later(order_id, status)
      NotifyUserServiceJob.perform_later(order_id, status)
    end

  # TODO: Implement logic to verify refund payment statuses
  # An order should have been previously marked as successful to be refunded
  # Communication between the payment service and the order service is required
  # to verify the refund eligibility

  # rubocop:enable Metrics/MethodLength
end
