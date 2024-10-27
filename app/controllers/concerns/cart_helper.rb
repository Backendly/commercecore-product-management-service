# frozen_string_literal: true

# Helper module for the cart resource.
module CartHelper
  # Retrieves the current user's cart.
  #
  # This method finds or creates a cart for the current user, app,
  # and developer.
  # It uses the cache to store the cart for future requests.
  #
  # === Parameters:
  # * +user_id+ (String): The UUID of the user associated with the cart.
  # * +app_id+ (String): The UUID of the app associated with the cart.
  # * +developer_id+ (String): The UUID of the developer associated with
  # the cart.
  #
  # === Returns:
  # * (Cart): The current user's cart.
  #
  def cart
    cart = Cart.find_or_create(user_id:, app_id:, developer_id:)
    key = "cart_#{developer_id}_#{app_id}_#{user_id}_#{cart.updated_at.to_i}"
    cache_resource(key) { cart }
  end
end
