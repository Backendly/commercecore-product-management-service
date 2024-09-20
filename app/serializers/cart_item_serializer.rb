# frozen_string_literal: true

# Serializer for the cart item resource.
class CartItemSerializer
  include JSONAPI::Serializer
  attributes :product_id, :quantity, :created_at, :updated_at

  belongs_to :product
  belongs_to :cart

  cache_options store: Rails.cache, namespace: 'json-serializer',
                expires_in: 1.hour

  def total_price
    object.product.price * object.quantity
  end
end
