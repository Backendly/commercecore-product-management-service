# frozen_string_literal: true

# spec/factories/categories.rb
FactoryBot.define do
  factory :category do
    name { "Electronics" }
    description { "Electronics and gadgets category" }
    developer_id { SecureRandom.uuid }
  end
end
