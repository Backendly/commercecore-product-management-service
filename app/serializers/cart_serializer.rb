# frozen_string_literal: true

# Serializer for the cart resource.
class CartSerializer
  include JSONAPI::Serializer
  attributes :user_id, :developer_id, :app_id, :created_at

  has_many :cart_items

  cache_options store: Rails.cache, namespace: 'json-serializer',
                expires_in: 1.hour
end
