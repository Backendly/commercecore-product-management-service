# frozen_string_literal: true

# Serializer for Products
class ProductSerializer
  include JSONAPI::Serializer

  attributes(
    *Product.attribute_names.map(&:to_sym).reject do |attr|
      %i[id category_id].include?(attr)
    end
  )

  belongs_to :category

  attribute :links do |product|
    {
      self: Rails.application.routes.url_helpers.api_v1_product_url(product)
    }
  end
end
