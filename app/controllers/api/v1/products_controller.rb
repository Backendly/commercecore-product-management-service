# frozen_string_literal: true

module Api
  module V1
    # rubocop:disable Metrics/ClassLength

    # Handles CRUD operations for products
    class ProductsController < ApplicationController
      before_action :set_product,
                    only: %i[show update destroy upload_images delete_image]
      before_action :set_product_image, only: %i[delete_image]

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize

      # GET /api/v1/products
      # Retrieves a paginated list of products for a developer.
      # Caches the response for 2 hours.
      def index
        page = params[:page] || 1

        # Initialize the products query with developer_id and app_id
        products = Product.where(developer_id:, app_id:)
                          .by_name(params[:name])
                          .by_category(params[:category_id])
                          .by_price_range(params[:min_price],
                                          params[:max_price])
                          .page(page)
                          .per(page_size)

        # Cache the collection of products
        response = cache_collection(
          products, base_key,
          page:, page_size:,
          filters: {
            name: params[:name],
            category_id: params[:category_id],
            min_price: params[:min_price],
            max_price: params[:max_price]
          }
        ) do |collection|
          json_response(
            collection, message: 'Products retrieved successfully',
                        serializer: ProductSerializer
          )
        end

        render json: response
      end

      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      # GET /api/v1/products/:id
      # Retrieves a specific product by ID.
      def show
        return unless stale?(
          @product, last_modified: @product.updated_at,
                    public: true
        )

        render json: json_response(
          @product,
          message: 'Product retrieved successfully',
          serializer:
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
          message: 'Product updated successfully',
          serializer:
        )
      end

      # DELETE /api/v1/products/:id
      # Deletes a specific product.
      def destroy
        @product.destroy!
        head :no_content
      end

      # Uploads images to the product.
      def upload_images
        if @product.images.attach(image_params)
          render json: { message: 'Images uploaded successfully' }
        else
          render_error(details: @product.errors.full_messages,
                       status: :unprocessable_content)
        end
      end

      # Deletes a specific image from the product.
      def delete_image
        @product_image.purge_later
        render json: { message: 'Image deleted successfully' }, status: :ok
      end

      private

        # Sets the product instance variable based on the provided ID and
        # developer token. If the product is found in the cache, it is assigned
        # to @product. If not found or the cached product is stale, it is
        # fetched from the database.
        def set_product
          @product = Product.find_by!(id: params[:id], developer_id:, app_id:)
          cache_key = "#{current_cache_key}_#{@product.updated_at.to_i}"
          @product = cache_resource(cache_key) { @product }
        end

        # Strong parameters for product creation and updates.
        def product_params
          params.require(:product)
                .permit(
                  :name, :description, :price, :category_id, :available,
                  :currency, :stock_quantity
                ).merge(developer_id:, user_id:, app_id:)
        end

        # Strong parameters for product image creation.
        def image_params
          params.require(:images)
        end

        # Returns the serializer class for the product.
        def serializer
          ProductSerializer
        end

        # Checks if the provided category ID is valid.
        def invalid_category_id?
          category_id = product_params[:category_id]
          category_id.present? && !valid_category_id?(category_id)
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
        def valid_category_id?(category_id)
          Rails.cache.fetch("category_#{category_id}_#{developer_token}") do
            Category.exists?(id: category_id, developer_id:)
          end
        end

        # Sets the product image based on the provided ID.
        def set_product_image
          @product_image = @product.images.find_by(id: params[:image_id])
          return unless @product_image.nil?

          render_error(
            error: 'Image not found', status: :not_found, details: {
              message: 'Verify you have the correct image ID',
              image_id: params[:image_id]
            }
          )
        end
    end

    # rubocop:enable Metrics/ClassLength
  end
end
