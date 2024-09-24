# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderStatusNotificationJob, type: :job do
  let!(:app_id) { SecureRandom.uuid }
  let!(:product) { FactoryBot.create(:product, app_id:) }
  let!(:order) { FactoryBot.create(:order, app_id:) }
  let!(:order_item) { FactoryBot.create(:order_item, order:, product:) }

  it 'notifies the user about the order status' do
    expect(ActionCable.server).to receive(:broadcast).with(
      "order_status_id:#{order.id}_user:#{order.user_id}", {
        order_id: order.id,
        status: order.status,
        total: order.total_amount.to_f,
        items: order.order_items.map do |item|
          { name: item.product.name, quantity: item.quantity }
        end
      }
    )

    OrderStatusNotificationJob.notify(order)
  end

  context 'when the order status is pending' do
    it 'notifies the user about the order status' do
      order.update(status: 'pending')
      expect(ActionCable.server).to receive(:broadcast).with(
        "order_status_id:#{order.id}_user:#{order.user_id}", {
          order_id: order.id,
          status: order.status,
          total: order.total_amount.to_f,
          items: order.order_items.map do |item|
            { name: item.product.name, quantity: item.quantity }
          end
        }
      )

      OrderStatusNotificationJob.notify(order)
    end
  end

  context 'when the order status is processing' do
    it 'notifies the user about the order status' do
      order.update(status: 'processing')
      expect(ActionCable.server).to receive(:broadcast).with(
        "order_status_id:#{order.id}_user:#{order.user_id}", {
          order_id: order.id,
          status: order.status,
          total: order.total_amount.to_f,
          items: order.order_items.map do |item|
            { name: item.product.name, quantity: item.quantity }
          end
        }
      )

      OrderStatusNotificationJob.notify(order)
    end
  end

  context 'when the order status is completed' do
    it 'notifies the user about the order status' do
      order.update(status: 'successful')
      expect(ActionCable.server).to receive(:broadcast).with(
        "order_status_id:#{order.id}_user:#{order.user_id}", {
          order_id: order.id,
          status: order.status,
          total: order.total_amount.to_f,
          items: order.order_items.map do |item|
            { name: item.product.name, quantity: item.quantity }
          end
        }
      )

      OrderStatusNotificationJob.notify(order)
    end
  end

  context 'when the order status is cancelled' do
    it 'notifies the user about the order status' do
      order.update(status: 'cancelled')
      expect(ActionCable.server).to receive(:broadcast).with(
        "order_status_id:#{order.id}_user:#{order.user_id}", {
          order_id: order.id,
          status: order.status,
          total: order.total_amount.to_f,
          items: order.order_items.map do |item|
            { name: item.product.name, quantity: item.quantity }
          end
        }
      )

      OrderStatusNotificationJob.notify(order)
    end
  end
end
