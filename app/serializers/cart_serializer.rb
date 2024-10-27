# frozen_string_literal: true

# Serializer for the cart resource.
class CartSerializer < BaseSerializer
  attributes :user_id, :developer_id, :app_id, :created_at, :updated_at

  has_many :cart_items
end
