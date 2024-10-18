# frozen_string_literal: true

# Order Item Serializer
class OrderItemSerializer < BaseSerializer
  attributes :quantity, :price_at_purchase

  belongs_to :order
  belongs_to :product

  link :self do |object|
    Rails.application.routes.url_helpers.api_v1_order_item_path(
      object.order, object
    )
  end

  link :order do |object|
    Rails.application.routes.url_helpers.api_v1_order_path(object.order)
  end

  link :product do |object|
    Rails.application.routes.url_helpers.api_v1_product_path(object.product)
  end
end
