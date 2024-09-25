# frozen_string_literal: true

Thread.new do
  Rails.logger.info 'Starting PaymentStatusListener thread'

  begin
    message_broker = Redis.new(url: ENV['MESSAGE_BROKER_URL'])

    message_broker.subscribe('payment_status') do |on|
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
          payment_status[:order_id], payment_status[:status]
        )

        Rails.logger.debug 'Enqueued PaymentStatusJob'
      end
    end
  rescue StandardError => e
    Rails.logger.error "Error in PaymentStatusListener: #{e.message}"
  end
end
