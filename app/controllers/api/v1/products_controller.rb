# frozen_string_literal: true

module Api
  module V1
    # rubocop:disable Metrics/ClassLength

    # Handles CRUD operations for products
    class ProductsController < ApplicationController
      before_action :set_product, only: %i[show update destroy]
      after_action :invalidate_cache, only: %i[update destroy]

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize

      # GET /api/v1/products
      # Retrieves a paginated list of products for a developer.
      # Caches the response for 2 hours.
      def index
        page = params[:page] || 1

        # Initialize the products query with developer_id and app_id
        products = Product.where(developer_id:, app_id:)
                          .page(page)
                          .per(page_size)

        # Apply filtering based on query parameters
        products = products.by_name(params[:name])
                           .by_category(params[:category_id])
                           .by_price_range(params[:min_price],
                                           params[:max_price])

        # Set the cache key based on the filtered products
        cache_key = products_cache_key(developer_id:, page:, page_size:,
                                       name: params[:name],
                                       category_id: params[:category_id],
                                       min_price: params[:min_price],
                                       max_price: params[:max_price])

        # Fetch or cache the response
        response = Rails.cache.fetch(cache_key, expires_in: 2.hours) do
          products_array = products.to_a
          json_response(
            products_array,
            message: 'Products retrieved successfully',
            serializer:
          )
        end

        render json: response
      end

      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      # GET /api/v1/products/:id
      # Retrieves a specific product by ID.
      def show
        render json: json_response(
          @product,
          serializer:,
          message: 'Product retrieved successfully'
        )
      end

      # POST /api/v1/products
      # Creates a new product.
      # Validates the presence of the category ID.
      def create
        return render_category_error if invalid_category_id?

        product = Product.create!(product_params)

        render json: json_response(
          product,
          message: 'Product created successfully',
          serializer:
        ), status: :created
      end

      # PATCH/PUT /api/v1/products/:id
      # Updates an existing product.
      def update
        @product.update!(product_params)

        render json: json_response(
          @product,
          serializer:,
          message: 'Product updated successfully'
        )
      end

      # DELETE /api/v1/products/:id
      # Deletes a specific product.
      def destroy
        @product.destroy!
        head :no_content
      end

      private

        # Sets the product instance variable based on the provided ID and
        # developer token. If the product is found in the cache, it is assigned
        # to @product. If not found or the cached product is stale, it is
        # fetched from the database.
        def set_product
          @product = Rails.cache.fetch(cache_key, expires_in: 2.hours) do
            Product.find_by!(id: params[:id], developer_id:, app_id:)
          end
        end

        # Strong parameters for product creation and updates.
        def product_params
          params.require(:product)
                .permit(:name, :description, :price, :category_id, :available,
                        :currency, :stock_quantity)
                .merge(developer_id:, user_id:, app_id:)
        end

        # Returns the serializer class for the product.
        def serializer
          ProductSerializer
        end

        # Checks if the provided category ID is valid.
        def invalid_category_id?
          category_id = product_params[:category_id]
          category_id.present? && !validate_category_id(category_id)
        end

        # Renders an error response for invalid category ID.
        def render_category_error
          render_error(
            error: 'Category not found',
            status: :bad_request,
            details: { message: 'Verify you have the category you specified' }
          )
        end

        # Validates the existence of a category by ID.
        def validate_category_id(category_id)
          Rails.cache.fetch("category_#{category_id}_#{developer_token}") do
            Category.exists?(id: category_id, developer_id:)
          end
        end

        # rubocop:disable Metrics/ParameterLists

        # Generates a cache key for product pagination based on developer ID
        # and page info.
        def products_cache_key(developer_id:, page:, page_size:, name: nil,
                               category_id: nil, min_price: nil, max_price: nil)

          key_parts = %W[developer_#{developer_id} page_#{page}
                         size-#{page_size}]

          key_parts << "name-#{name}" if name.present?
          key_parts << "category_id-#{category_id}" if category_id.present?
          key_parts << "min_price-#{min_price}" if min_price.present?
          key_parts << "max_price-#{max_price}" if max_price.present?

          key_parts.join('_')
        end

        # rubocop:enable Metrics/ParameterLists

        # Generates the cache key for the specific product.
        def cache_key
          "product_#{params[:id]}_#{developer_id}"
        end

        # Invalidates the cache for the product and its updated_at timestamp.
        def invalidate_cache
          Rails.cache.delete(cache_key)
          Rails.cache.delete(updated_at_cache_key)
        end

        # Generates the cache key for the product's updated_at timestamp.
        def updated_at_cache_key
          "#{cache_key}_updated_at"
        end
    end
  end

  # rubocop:enable Metrics/ClassLength
end
