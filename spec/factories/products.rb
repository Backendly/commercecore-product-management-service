# frozen_string_literal: true

FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    description { Faker::Lorem.sentence(word_count: 15) }
    price { 99.99 }
    stock_quantity { 100 }

    # Simulate the IDs for user, developer, and app as UUIDs
    user_id { SecureRandom.uuid }
    developer_id { SecureRandom.uuid }
    app_id { SecureRandom.uuid }

    # Associate product with a real category
    association :category

    # Optionally create attached images as well
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
