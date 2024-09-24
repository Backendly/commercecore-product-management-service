# frozen_string_literal: true

# Payment status listener
class PaymentStatusListenerJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.debug 'Starting PaymentStatusListenerJob'

    message_broker.subscribe('payment_status') do |on|
      Rails.logger.debug 'Subscribed to Redis channel'
      on.message do |_channel, message|
        Rails.logger.debug "Received message: #{message}"

        begin
          payment_status = JSON.parse(message, symbolize_names: true)
        rescue JSON::ParserError
          Rails.logger.error "Invalid JSON: #{message}"
          next
        end

        unless payment_status[:order_id] && payment_status[:status]
          Rails.logger.error "Missing order_id or status: #{message}"
          next
        end

        PaymentStatusJob.perform_later(
          payment_status[:order_id],
          payment_status[:status]
        )

        Rails.logger.debug 'Enqueued PaymentStatusJob'
      end
    end
  rescue StandardError
    Rails.logger.error 'Error processing payment status message'
  end
end
