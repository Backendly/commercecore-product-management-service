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

  attribute :images do |product|
    product.images.map do |image|
      { id: image.id,
        url: Rails.application.routes.url_helpers.rails_blob_url(
          image, only_path: true
        ) }
    end
  end

  cache_options store: Rails.cache, namespace: 'jsonapi-serializer',
                expires_in: 2.hours
end
