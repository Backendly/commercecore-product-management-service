# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

# This thread listens to the Payment Service for order validations. It verifies
# that the order provided provided along with the developer_id and app_id are
# valid and active in the database. It also verifies that the order belongs to
# who is asking.
Thread.new do
  Rails.logger.info "Starting Order validation for payment service thread"
  message_broker = Redis.new(url: ENV["MESSAGE_BROKER_URL"])

  message_broker.subscribe("validate_order") do |on|
    on.message do |_channel, message|
      begin
        data = JSON.parse(message, symbolize_names: true)
      rescue JSON::ParserError
        Rails.logger.error "Invalid JSON: #{message}"

        message_broker.publish(
          "invalid_order", { error: "Invalid JSON data", data: }.to_json
        )
        next
      end

      required_keys = %i[order_id app_id developer_id user_id]

      unless required_keys.all? { |key| data.key?(key) }
        message_broker.publish(
          "invalid_order", {
            error: "Message data missing required data",
            required_keys:
          }.to_json
        )

        Rails.logger.error("Missing required order information")
        next
      end

      data[:id] = data.delete(:order_id)

      order = Order.find_by(**data)

      if order.nil?
        message_broker.publish(
          "invalid_order", {
            error: "Order not found",
            message: "Order with ID#: '#{data[:id]}' does not exist"
          }.to_json
        )

        Rails.logger.error("Non-existent Order with ID: #{data["id"]}")
      else
        PaymentServiceNotifierJob.perform_now(order)
      end
    end
  end
end

# rubocop:enable Metrics/BlockLength
