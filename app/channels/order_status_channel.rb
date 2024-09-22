# frozen_string_literal: true

# Channel for order status updates
class OrderStatusChannel < ApplicationCable::Channel
  def subscribed
    @user_id = params[:user_id]
    @order_id = params[:order_id]

    stream_from "order_status_id:#{@order_id}_user:#{@user_id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
