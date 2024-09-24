# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderStatusChannel, type: :channel do
  let(:user_id) { SecureRandom.uuid }
  let(:order) { FactoryBot.create(:order, user_id:) }
  let(:order_item) { FactoryBot.create(:order_item, order:) }
  let(:order_status_channel) { "order_status_id:#{order.id}_user:#{user_id}" }

  it 'subscribes to a stream' do
    subscribe(user_id:, order_id: order.id)
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from(order_status_channel)
  end

  it 'broadcasts the order status' do
    subscribe(user_id:, order_id: order.id)
    expect(subscription).to have_stream_from(order_status_channel)

    expect do
      OrderStatusNotificationJob.notify(order)
    end.to have_broadcasted_to(order_status_channel).with(
      order_id: order.id,
      status: order.status,
      total: order.total_amount.to_s,
      items: order.order_items.map do |item|
        { name: item.product.name, quantity: item.quantity }
      end
    )
  end

  it 'unsubscribes from a stream' do
    subscribe(user_id:, order_id: order.id)
    expect(subscription).to have_stream_from(order_status_channel)

    unsubscribe
    expect(subscription).to_not have_streams
  end
end
