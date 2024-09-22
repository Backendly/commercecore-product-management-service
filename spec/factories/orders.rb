# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    user_id { SecureRandom.uuid }
    developer_id { SecureRandom.uuid }
    app_id { SecureRandom.uuid }
    total_amount { 9.99 }
  end
end
