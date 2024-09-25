# frozen_string_literal: true

# Order status update job
class UpdateOrderStatusJob < ApplicationJob
  queue_as :default

  def perform(order_id, status)
    order = Order.find_by(id: order_id)

    Rails.logger.info(
      "Updating order status to #{status} for order ID #{order_id}"
    )

    if order
      order.update!(status:)
    else
      Rails.logger.error("Order with ID #{order_id} not found")
    end
  end
end
