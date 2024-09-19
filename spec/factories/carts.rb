# frozen_string_literal: true

FactoryBot.define do
  factory :cart do
    user_id { SecureRandom.uuid }
    developer_id { SecureRandom.uuid }
    app_id { SecureRandom.uuid }
  end
end
