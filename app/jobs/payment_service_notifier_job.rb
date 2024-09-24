# frozen_string_literal: true

# Job to notify the payment service about a new order
class PaymentServiceNotifierJob < ApplicationJob
  queue_as :default

  # Notify the payment service service that the job has been cancelled
  def self.cancel_order(order)
    new.perform(order)
  end

  def perform(order)
    notify_payment_service(order)

    OrderStatusNotificationJob.notify(order)

    PaymentStatusListenerJob.perform_later
  end

  private

    def notify_payment_service(order)
      message_broker.publish(publish_channel(order), {
        order_id: order.id,
        user_id: order.user_id,
        app_id: order.app_id,
        total: order.total_amount,
        status: order.status,
        developer_id: order.developer_id
      }.to_json)
    end

    def publish_channel(order)
      if order.cancelled?
        'payment_order_cancelled'
      else
        'payment_order_created'
      end
    end
end
