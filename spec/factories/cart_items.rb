# frozen_string_literal: true

FactoryBot.define do
  factory :cart_item do
    association :cart
    association :product
    quantity { 1 }
  end
end
