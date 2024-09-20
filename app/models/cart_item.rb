# frozen_string_literal: true

# This class represents a single item in a shopping cart.
# It is associated with a cart and a product.
class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :cart_id, :product_id, :quantity, presence: true
  validates :quantity, numericality: { greater_than: 0 }

  before_update :prevent_cart_id_change

  private

    def prevent_cart_id_change
      return unless cart_id_changed?

      errors.add(:cart_id, 'cannot be changed once set')
      raise ActiveRecord::ReadonlyAttributeError,
            'cart_id cannot be changed once set'
    end
end
