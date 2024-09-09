# frozen_string_literal: true

module Api
  module V1
    # Controller for version of Categories side of Product Management Service
    # This controller handles CRUD operations for categories.
    class CategoriesController < ApplicationController
      # Maximum number of items to be returned in a single page
      MAX_PAGINATION_SIZE = 100

      # Before actions to set up authorization and category object
      before_action :authorization_credentials
      before_action :set_api_v1_category, only: %i[show update destroy]

      # GET /api/v1/categories
      # GET /api/v1/categories.json
      # Retrieves a paginated list of categories filtered by developer token
      def index
        # Fetch categories with pagination
        categories = Category.page(params.fetch(:page, 1)).per(page_size)

        categories = perform_filtering(categories)

        # Render the JSON response with the categories
        render json: json_response(
          categories, serializer:,
                      message: 'Categories retrieved successfully'
        )
      end

      # GET /api/v1/categories/1
      # GET /api/v1/categories/1.json
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

        if @category.save
          # Render the JSON response with the created category
          render json: json_response(@category,
                                     message: 'Category created successfully',
                                     serializer:), status: :created
        else
          # Render an error response if the category could not be created
          render_error(error: category.errors,
                       status: :unprocessable_content)
        end
      end

      # PATCH/PUT /api/v1/categories/1
      # PATCH/PUT /api/v1/categories/1.json
      # Updates an existing category
      def update
        if @category.update(api_v1_category_params)
          # Render the JSON response with the updated category
          render json: json_response(@category,
                                     serializer:,
                                     message: 'Category updated successfully')
        else
          # Render an error response if the category could not be updated
          render json: category.errors, status: :unprocessable_content
        end
      end

      # DELETE /api/v1/categories/1
      # DELETE /api/v1/categories/1.json
      # Deletes a specific category by ID
      def destroy
        @category.destroy!
        # Respond with no content status
        head :no_content
      end

      private

        # Reader method for the category instance variable
        attr_reader :category

        # Determines the page size for pagination, ensuring it does not exceed
        # the maximum limit
        def page_size
          [
            params.fetch(:page_size, MAX_PAGINATION_SIZE).to_i,
            MAX_PAGINATION_SIZE
          ].min
        end

        # Sets the category instance variable based on the ID and developer
        # token
        def set_api_v1_category
          @category = Category.find_by!(
            id: params[:id],
            developer_id: developer_token
          )
        end

        # Only allow a list of trusted parameters through.
        # Permits the name and description parameters and merges the developer
        # token
        def api_v1_category_params
          params.require(:category)
                .permit(:name, :description)
                .merge(developer_id: developer_token)
        end

        # Returns the serializer class for the category
        def serializer
          CategorySerializer
        end

        # Returns the developer token from the request headers
        def developer_token
          request.headers.fetch('X-Developer-Token', nil)
        end

        # Validates the developer token before processing the request
        def authorization_credentials
          return if valid_developer_token?

          # Render an error response if the developer token is invalid
          render_error(
            error: 'Authorization failed',
            details: {
              error: 'Invalid developer token',
              message: 'Please provide a valid developer token'
            },
            status: :unauthorized
          )
        end

        # This method calls the user service API to validate the developer token
        #
        # TODO: Implement the actual API call to the user service
        def valid_developer_token?
          # Placeholder for actual API call
          # response = UserApiService.validate_token(developer_token)
          #
          # return true if response.code == 200
          #
          # false

          # Temporary validation logic
          if developer_token.nil?
            false
          else
            true
          end
        end

        def perform_filtering(categories)
          # Filter categories by developer token
          categories = categories.where(developer_id: developer_token)

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
