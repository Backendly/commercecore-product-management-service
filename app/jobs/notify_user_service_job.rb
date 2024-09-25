# frozen_string_literal: true

# User service notification for orders
class NotifyUserServiceJob < ApplicationJob
  queue_as :default

  # rubocop:disable Metrics/MethodLength

  def perform(order_id, status)
    order = Order.find_by(id: order_id)

    if order.nil?
      Rails.logger.error "Order with ID: #{order_id} not found"
      return
    end

    message_broker.publish('user_order_notification', {
      order_id: order.id,
      user_id: order.user_id,
      status:,
      total_amount: order.total_amount
    }.to_json)
  end
end

# rubocop:enable Metrics/MethodLength
