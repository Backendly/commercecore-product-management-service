# frozen_string_literal: true

# Payment status job
class PaymentStatusJob < ApplicationJob
  queue_as :high_priority

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize

  def perform(order_id, status)
    order = Order.find_by(id: order_id)

    unless order
      Rails.logger.error("Order with ID #{order_id} not found")
      return
    end

    case status
      when 'succeeded'
        UpdateOrderStatusJob.perform_later(order.id, 'successful')
        NotifyUserServiceJob.perform_later(order.id, 'successful')
        UpdateProductStockJob.perform_later(order.id)
        ClearCartJob.perform_later(order.user_id)
      when 'created'
        UpdateOrderStatusJob.perform_later(order.id, 'processing')
        NotifyUserServiceJob.perform_later(order.id, 'processing')
      when 'failed'
        UpdateOrderStatusJob.perform_later(order.id, 'failed')
        NotifyUserServiceJob.perform_later(order.id, 'failed')
      else
        Rails.logger.error "Invalid status: #{status}"
        return
    end

    OrderStatusNotificationJob.notify(order)
  end

  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
end
