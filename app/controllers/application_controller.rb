# frozen_string_literal: true

# Base controller for API controllers
class ApplicationController < ActionController::API
  include Authentication
  include JsonResponse
  include Cacheable

  rescue_from ActiveRecord::RecordNotFound, with: :object_not_found
  rescue_from ActiveRecord::RecordNotUnique, with: :duplicate_object
  rescue_from ActiveRecord::RecordInvalid, with: :validation_error
  rescue_from NoMethodError, NameError, with: :internal_server_error
  rescue_from ActionController::RoutingError, with: :invalid_route
  rescue_from ActionController::ParameterMissing, with: :bad_request

  # rubocop:disable Metrics/MethodLength

  # Renders a JSON error response
  def render_error(status:, error: 'An error occurred', details: nil, meta: {})
    numeric_status_code = Rack::Utils.status_code(status)
    success = false

    # Default meta information
    default_meta = {
      request_path: request.url,
      request_method: request.method,
      status_code: numeric_status_code,
      success:
    }

    # Merge default meta with custom meta
    final_meta = default_meta.merge(meta)

    render json: {
      error:,
      meta: final_meta,
      details:
    }, status: numeric_status_code
  end

  # rubocop:enable Metrics/MethodLength

  def invalid_route
    render_error(
      error: 'Route not found',
      details: { message: "Invalid route: #{request.path}" },
      status: :not_found
    )
  end

  private

    # Handles exceptions raised when database objects are not found
    def object_not_found(error)
      render_error(
        error: "#{error.model} not found",
        details: {
          message: "Couldn't find #{error.model} with id #{params[:id]}"
        },
        status: :not_found
      )
    end

    # Handles unique constraint violation errors
    def duplicate_object(error)
      match_data = error.message.match(/Key \((.+)\)=\((.+)\) already exists/)
      details = if match_data
                  field, value = match_data.captures
                  "A record with #{field} '#{value}' already exists."
                else
                  'A record with that name already exists.'
                end

      render_error(error: 'Duplicate object found',
                   details:, status: :conflict)
    end

    # Handles generic server errors like NoMethodError or NameError
    def internal_server_error(error)
      logger.error "#{error.class.name}: #{error.message}"
      render_error(
        error: 'Internal Server Error',
        status: :internal_server_error
      )
    end

    # Handles validation errors
    def validation_error(error)
      render_error(
        error: 'Validation Failed',
        details: error.record.errors.to_hash(full_messages: true),
        status: :unprocessable_content
      )
    end

    def bad_request(error)
      render_error(
        error: 'Bad Request',
        details: error.message,
        status: :bad_request
      )
    end
end
