# frozen_string_literal: true

# Category Serializer
class CategorySerializer < BaseSerializer
  attributes :name, :description, :developer_id, :created_at, :updated_at

  attribute :links do |category|
    { self: Rails.application.routes.url_helpers.api_v1_category_url(category) }
  end
end
