# frozen_string_literal: true

module Api
  module V1
    # Controller for version of Categories side of Product Management Service
    # This controller handles CRUD operations for categories.
    class CategoriesController < ApplicationController
      # Before actions to set up authorization and category object
      before_action :set_category, only: %i[show update destroy]

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize

      # GET /api/v1/categories
      # GET /api/v1/categories.json
      # Retrieves a paginated list of categories filtered by developer token
      def index
        categories = Category.by_developer(developer_id)
                             .by_name(params[:name])
                             .by_search(params[:search])
                             .page(params[:page])
                             .per(page_size)

        # implement caching for the collection of categories
        response = cache_collection(
          categories, base_key,
          page: params[:page],
          page_size:,
          filters: {
            name: params[:name],
            search: params[:search]
          }
        ) do |collection|
          json_response(
            collection,
            message: 'Categories retrieved successfully',
            serializer:
          )
        end

        render json: response
      end

      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize

      # GET /api/v1/categories/:id
      # GET /api/v1/categories/:id.json
      # Retrieves a specific category by ID
      def show
        render json: json_response(
          category,
          message: 'Category retrieved successfully',
          serializer:
        )
      end

      # POST /api/v1/categories
      # POST /api/v1/categories.json
      # Creates a new category
      def create
        @category = Category.create!(category_params)

        # Render the JSON response with the created category
        render json: json_response(@category,
                                   message: 'Category created successfully',
                                   serializer:), status: :created
      end

      # PATCH/PUT /api/v1/categories/:id
      # PATCH/PUT /api/v1/categories/:id.json
      # Updates an existing category
      def update
        if @category.update!(category_params)
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
        def set_category
          @category = cache_resource(current_cache_key, expires_in: 12.hours) do
            Category.find_by!(id: params[:id], developer_id:)
          end
        end

        # Only allow a list of trusted parameters through.
        # Permits the name and description parameters and merges the developer
        # token
        def category_params
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
