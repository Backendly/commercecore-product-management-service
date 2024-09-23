# frozen_string_literal: true

# Cart clearance job
#
# This job clears the cart for the next user order
class ClearCartJob < ApplicationJob
  queue_as :default

  def perform(user_id)
    cart = Cart.find_by(user_id:)

    if cart
      cart.cart_items.destroy_all
    else
      Rails.logger.error "No cart found for user_id: #{user_id}"
    end
  end
end
