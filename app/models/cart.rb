# frozen_string_literal: true

# This class represents a shopping cart in the application.
# It has a one-to-many relationship with CartItem, where a cart can have multiple cart items.
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

  def prevent_update
    raise ActiveRecord::ReadOnlyRecord, 'Carts cannot be updated after creation'
  end
end
