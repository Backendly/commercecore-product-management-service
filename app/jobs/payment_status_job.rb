# frozen_string_literal: true

# Payment status job
class PaymentStatusJob < ApplicationJob
  queue_as :default

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize

  def perform(order_id, status)
    order = Order.find(order_id)

    return unless order

    case status
      when 'succeeded'
        UpdateProductStockJob.perform_later(order.id)
        ClearCartJob.perform_later(order.user_id)
        UpdateOrderStatusJob.perform_later(order.id, 'successful')
        NotifyUserServiceJob.perform_later(order.id, 'successful')
      when 'created'
        UpdateOrderStatusJob.perform_later(order.id, 'processing')
        NotifyUserServiceJob.perform_later(order.id, 'processing')
      when 'failed'
        UpdateOrderStatusJob.perform_later(order.id, 'failed')
        NotifyUserServiceJob.perform_later(order.id, 'failed')
    end

    OrderStatusNotificationJob.notify(order)
  end

  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
end
