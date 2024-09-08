# frozen_string_literal: true

# Base controller for API controllers
class ApplicationController < ActionController::API
  include JsonResponse

  rescue_from ActiveRecord::RecordNotFound, with: :object_not_found
  rescue_from ActiveRecord::RecordNotUnique, with: :duplicate_object
  rescue_from NoMethodError, NameError, with: :internal_server_error
  rescue_from ActionController::RoutingError, with: :invalid_route

  def render_error(message: 'An error occurred', status: :bad_request,
    details: nil)
    numeric_status_code = Rack::Utils.status_code(status)

    render json: { message:, status_code: numeric_status_code,
      success: false, details: },
      status: numeric_status_code
  end

  def invalid_route
    render_error(message: 'Route not found',
      details: { path: request.path,
        method: request.method }, status: :not_found)
  end

  private

    # Handles exceptions raised when database objects are not found
    def object_not_found(error)
      render_error(details: error.message, status: :not_found)
    end

    def duplicate_object(error)
      render_error(details: error.message, status: :conflict)
    end

    def internal_server_error(_error)
      render_error(message: 'Internal Server Error',
        status: :internal_server_error)
    end
end
