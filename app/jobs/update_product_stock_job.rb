# frozen_string_literal: true

# Product stock update job
class UpdateProductStockJob < ApplicationJob
  queue_as :default

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize

  def perform(order_id, status: nil)
    order = Order.find_by(id: order_id)

    if order.nil?
      Rails.logger.error("Order with ID #{order_id} not found")
      return
    end

    unless order.successful?
      Rails.logger.error("Order with ID #{order_id} is not successful")
      return
    end

    Rails.logger.info <<~INFO
      Order ID: #{order.id}
      Order status: #{order.status}
      Order items: #{order.order_items}
    INFO

    order.order_items.each do |item|
      product = Product.find_by(id: item.product_id)

      action = status == "refunded" ? "restore" : "remove"

      Rails.logger.info <<~INFO
        Updating stock for product with ID #{product.id}
        Current stock quantity: #{product.stock_quantity}
        Quantity to #{action}: #{item.quantity}
      INFO

      new_stock_quantity = if status == "refunded"
                             Rails.logger.info "Refunding stock"
                             product.stock_quantity + item.quantity
      else
                             product.stock_quantity - item.quantity
      end

      product.update!(
        stock_quantity: new_stock_quantity,
        available: new_stock_quantity.positive?
      )
    end
  end

  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
end
