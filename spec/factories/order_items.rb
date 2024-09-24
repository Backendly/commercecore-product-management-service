# frozen_string_literal: true

FactoryBot.define do
  factory :order_item do
    association :product
    association :order
    quantity { 1 }
    price_at_purchase { product.price }
  end
end
