# frozen_string_literal: true

# Payment status listener
class PaymentStatusListenerJob < ApplicationJob
  queue_as :default

  def perform
    Redis.new.subscribe('payment_status') do |on|
      on.message do |_channel, message|
        payment_status = JSON.parse(message, symbolize_names: true)

        PaymentStatusJob.perform_later(
          payment_status[:order_id],
          payment_status[:status]
        )
      end
    end
  end
end
