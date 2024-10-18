# frozen_string_literal: true

# Serializer for the cart item resource.
class CartItemSerializer < BaseSerializer
  attributes :quantity, :created_at, :updated_at

  belongs_to :product

  attribute :product do |cart_item|
    {
      id: cart_item.product.id,
      name: cart_item.product.name,
      unit_price: cart_item.product.price
    }
  end

  attribute :total_price do |cart_item|
    cart_item.product.price * cart_item.quantity
  end
end
