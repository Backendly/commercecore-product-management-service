# frozen_string_literal: true

# This class represents a shopping cart in the application.
# It has a one-to-many relationship with CartItem, where a cart can have
# multiple cart items.
#
# Attributes:
# - user_id: The ID of the user who owns the cart.
# - developer_id: The ID of the developer associated with the cart.
# - app_id: The ID of the app associated with the cart.
#
# Associations:
# - cart_items: The cart items associated with the cart.
#
# Validations:
# - user_id: Must be present.
# - developer_id: Must be present.
# - app_id: Must be present.
class Cart < ApplicationRecord
  has_many :cart_items, dependent: :destroy

  before_update :prevent_update

  validates :user_id, :developer_id, :app_id, presence: true

  # This method finds a cart by user_id and app_id, or creates a new one
  # if not found. The developer who created the cart is also associated with
  # it for tracking.
  #
  # Parameters:
  # - user_id: (String) The UUID of the user who owns the cart.
  # - app_id: (String) The UUID of the app associated with the cart.
  # - developer_id: (String) The UUID of the developer associated with the
  #   cart.
  #
  # Returns:
  # - (Cart) The found or created cart.
  #
  def self.find_or_create(user_id:, app_id:, developer_id:)
    cart = find_by(user_id:, app_id:)
    cart || create(user_id:, app_id:, developer_id:)
  end

  # This method adds or updates a cart item in the current cart.
  # If the cart item already exists, it updates the quantity; otherwise,
  # it creates a new cart item.
  #
  # Parameters:
  # - product_id: (String) The UUID of the product associated with the cart
  # item.
  # - quantity: (Integer) The quantity of the product in the cart item.
  #
  # Returns:
  # - (CartItem) The updated or created cart item.
  #
  def add_or_update_item(cart_item_params)
    cart_item = cart_items.find_or_initialize_by(
      product_id: cart_item_params[:product_id]
    )
    is_new_record = cart_item.new_record?
    cart_item.assign_attributes(cart_item_params)
    cart_item.save

    [ cart_item, is_new_record ]
  end

  private

    # Prevents updates to the cart after it is created
    def prevent_update
      raise ActiveRecord::ReadOnlyRecord,
        "Carts cannot be updated after creation"
    end
end
