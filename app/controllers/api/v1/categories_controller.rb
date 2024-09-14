# frozen_string_literal: true

module Api
  module V1
    # Controller for version of Categories side of Product Management Service
    # This controller handles CRUD operations for categories.
    class CategoriesController < ApplicationController
      # Before actions to set up authorization and category object
      before_action :set_api_v1_category, only: %i[show update destroy]

      # GET /api/v1/categories
      # GET /api/v1/categories.json
      # Retrieves a paginated list of categories filtered by developer token
      def index
        categories = Category.all

        categories = perform_filtering(categories)

        paginated_categories = categories.page(params[:page]).per(page_size)

        render json: json_response(
          paginated_categories, serializer:,
                                message: 'Categories retrieved successfully'
        )
      end

      # GET /api/v1/categories/:id
      # GET /api/v1/categories/:id.json
      # Retrieves a specific category by ID
      def show
        # Render the JSON response with the category
        render json: json_response(
          category, serializer:,
                    message: 'Category retrieved successfully'
        )
      end

      # POST /api/v1/categories
      # POST /api/v1/categories.json
      # Creates a new category
      def create
        @category = Category.new(api_v1_category_params)

        @category.save! # Raise an error when the category could not be saved

        # Render the JSON response with the created category
        render json: json_response(@category,
                                   message: 'Category created successfully',
                                   serializer:), status: :created
      end

      # PATCH/PUT /api/v1/categories/:id
      # PATCH/PUT /api/v1/categories/:id.json
      # Updates an existing category
      def update
        if @category.update!(api_v1_category_params)
          # Render the JSON response with the updated category
          render json: json_response(@category,
                                     serializer:,
                                     message: 'Category updated successfully')
        else
          # Render an error response if the category could not be updated
          render json: category.errors, status: :unprocessable_content
        end
      end

      # DELETE /api/v1/categories/:id
      # DELETE /api/v1/categories/:id.json
      #
      # Deletes a specific category by ID
      def destroy
        @category.destroy!
        # Respond with no content status
        head :no_content
      end

      private

        # Reader method for the category instance variable
        attr_reader :category

        # Sets the category instance variable based on the ID and developer
        # token
        def set_api_v1_category
          cache_key = "category/#{params[:id]}_#{developer_id}"
          @category = Rails.cache.fetch(cache_key, expires_in: 12.hours) do
            Category.find_by!(
              id: params[:id],
              developer_id:
            )
          end
        end

        # Only allow a list of trusted parameters through.
        # Permits the name and description parameters and merges the developer
        # token
        def api_v1_category_params
          params.require(:category)
                .permit(:name, :description)
                .merge(developer_id:)
        end

        # Returns the serializer class for the category
        def serializer
          CategorySerializer
        end

        def perform_filtering(categories)
          # Filter categories by developer token
          categories = categories.where(developer_id:)

          # Filter categories by name
          if params[:name].present?
            categories = categories.where('name ILIKE ?', "%#{params[:name]}%")
          end

          # filter categories by the search term, so any category that
          # has the search term in its name or description will be returned
          return categories if params[:search].blank?

          categories.where(
            'name ILIKE :search OR description ILIKE :search',
            search: "%#{params[:search]}%"
          )
        end
    end
  end
end
