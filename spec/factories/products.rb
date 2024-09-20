# frozen_string_literal: true

# spec/factories/products.rb
FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    description { Faker::Lorem.sentence(word_count: 15) }
    price { 99.99 }
    stock_quantity { 100 }
    developer_id { category.developer_id }
    user_id { SecureRandom.uuid }
    app_id { SecureRandom.uuid }
    association :category

    after(:build) do |product|
      product.images.attach(
        io: File.open(
          Rails.root.join(
            "spec/fixtures/files/product_image_1.png"
          )
        ),
        filename: 'product_image_1.png',
        content_type: 'image/png'
      )
    end
  end
end
