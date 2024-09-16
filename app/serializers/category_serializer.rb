# frozen_string_literal: true

# Category Serializer
class CategorySerializer
  include JSONAPI::Serializer

  attributes :name, :description, :developer_id, :created_at, :updated_at

  cache_options store: Rails.cache, namespace: 'jsonapi-serializer',
                expires_in: 1.hour

  attribute :links do |category|
    { self: Rails.application.routes.url_helpers.api_v1_category_url(category) }
  end
end
