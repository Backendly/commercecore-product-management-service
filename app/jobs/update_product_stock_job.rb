# frozen_string_literal: true

# Product stock update job
class UpdateProductStockJob < ApplicationJob
  queue_as :default

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize

  def perform(order_id)
    order = Order.find_by(id: order_id)

    unless order
      Rails.logger.error("Order with ID #{order_id} not found")
      return
    end

    unless order.successful?
      Rails.logger.error("Order with ID #{order_id} is not successful")
      return
    end

    Rails.logger.info "Order ID: #{order.id}"
    Rails.logger.info "Order status: #{order.status}"
    Rails.logger.info "Order items: #{order.order_items}"

    order.order_items.each do |item|
      product = Product.find_by(id: item.product_id)

      Rails.logger.info "Updating stock for product with ID #{product.id}"
      Rails.logger.info "Current stock quantity: #{product.stock_quantity}"
      Rails.logger.info "Quantity to remove: #{item.quantity}"

      product.update!(
        stock_quantity: product.stock_quantity - item.quantity,
        available: product.stock_quantity.positive?
      )
    end
  end

  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
end
