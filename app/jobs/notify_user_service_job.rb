# frozen_string_literal: true

# User service notification for orders
class NotifyUserServiceJob < ApplicationJob
  queue_as :default

  def perform(order_id, status)
    order = Order.find(order_id)

    message_broker.publish('user_order_notification', {
      order_id: order.id,
      user_id: order.user_id,
      status:,
      total_amount: order.total_amount
    }.to_json)
  end
end
