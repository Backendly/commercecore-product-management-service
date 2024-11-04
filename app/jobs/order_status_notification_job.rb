# frozen_string_literal: true

# Job to notify the user about the order status
class OrderStatusNotificationJob
  # rubocop:disable Metrics/MethodLength

  # Notify the user about the order
  def self.notify(order)
    Rails.logger.debug "OrderNotificationJob: Notifying order status to " \
      "user #{order.user_id} with order id #{order}"

    ActionCable.server.broadcast(
      "order_status_id:#{order.id}_user:#{order.user_id}", {
        order_id: order.id,
        status: order.status,
        total: order.total_amount,
        items: order.order_items.map do |item|
          { name: item.product.name, quantity: item.quantity }
        end
      }
    )
  end

  # rubocop:enable Metrics/MethodLength
end
