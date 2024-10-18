# frozen_string_literal: true

# Order Serializer
class OrderSerializer < BaseSerializer
  attributes :user_id, :developer_id, :app_id, :status, :total_amount,
             :created_at, :updated_at

  has_many :order_items

  link :self do |object|
    Rails.application.routes.url_helpers.api_v1_order_url(object)
  end

  link :related do |object|
    Rails.application.routes.url_helpers.api_v1_order_items_url(object)
  end
end
