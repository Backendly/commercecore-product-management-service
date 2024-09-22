# frozen_string_literal: true

# OrderItem model
class OrderItem < ApplicationRecord
  belongs_to :order, touch: true
  belongs_to :product, touch: true

  validates :price_at_purchase, :quantity, :product_id, :order_id,
            presence: true
  validate :product_and_order_belong_to_same_app

  validates :quantity, numericality: { greater_than: 0 }

  private

    def product_and_order_belong_to_same_app
      return unless product&.app_id != order&.app_id

      errors.add(:base, 'Product must belong to the same app as the order')
    end
end
