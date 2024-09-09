# frozen_string_literal: true

# Authentication mixin
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :verify_authentication_credentials!
  end

  # Retrieves the developer's token from the headers
  def developer_token
    request.headers.fetch('X-Developer-Token', nil)
  end

  private

    # Validates both developer token and user ID
    def verify_authentication_credentials!
      verify_developer_token!

      return if skip_user_id_verification?

      begin
        verify_user_id!
      rescue StandardError
        nil
      end
    end

    # Checks if the request is in CategoriesController
    def skip_user_id_verification?
      is_a?(Api::V1::CategoriesController)
    end

    # Verifies the developer token
    def verify_developer_token!
      return if valid_developer_token?

      render_error(
        error: 'Authorization failed',
        details: {
          error: 'Invalid developer token',
          message: 'Please provide a valid developer token'
        },
        status: :unauthorized
      )
    end

    # Verifies the user ID
    def verify_user_id!
      user_id = request.headers.fetch('X-User-ID', nil)
      return if valid_user_id?(user_id)

      render_error(
        error: 'Authorization failed',
        details: {
          error: 'Invalid user ID',
          message: 'Please provide a valid user ID'
        },
        status: :unauthorized
      )
    end

    # Placeholder for actual user ID validation logic
    def valid_user_id?(user_id)
      user_id.present? # Temporary logic
    end

    # Placeholder for actual developer token validation logic
    def valid_developer_token?
      developer_token.present?
    end
end
