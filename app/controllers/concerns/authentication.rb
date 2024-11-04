# frozen_string_literal: true

# app/controllers/concerns/authentication.rb
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :verify_authentication_credentials!
  end

  def developer_id
    Rails.cache.fetch("developer:#{developer_token}")
  end

  def user_id
    request.headers.fetch("X-User-Id", nil)
  end

  def app_id
    request.headers.fetch("X-App-Id", nil)
  end

  private

    def developer_token
      request.headers.fetch("X-Developer-Token", nil)
    end

    def verify_authentication_credentials!
      return unless verify_developer_token!
      return if skip_user_id_verification?

      return unless verify_user_id!

      verify_app_id!
    end

    def skip_user_id_verification?
      is_a?(Api::V1::CategoriesController)
    end

    # rubocop:disable Metrics/MethodLength
    def verify_developer_token!
      cached_developer = user_service_client.fetch_developer_id(
        developer_token:
      )

      if cached_developer
        true
      else
        render_error(
          error: "Authorization failed",
          details: {
            error: "Invalid developer token",
            message: "Please provide a valid developer token in the header. " \
              "E.g., X-Developer-Token: <developer_token>"
          },
          status: :unauthorized
        )
        false
      end
    end

    def verify_user_id!
      cached_user = user_service_client.fetch_user(
        user_id:, app_id:, developer_token:
      )

      if cached_user
        true
      else
        render_error(
          error: "Authorization failed",
          details: {
            error: "Invalid user ID",
            message: "Please provide a valid user ID. " \
              "E.g., X-User-Id: <user_id>"
          },
          status: :unauthorized
        )
        false
      end
    end

    def verify_app_id!
      cached_app = user_service_client.fetch_app(app_id:, developer_token:)
      return if cached_app

      render_error(
        error: "Authorization failed",
        details: {
          error: "Invalid app ID",
          message: "Please provide a valid app ID. E.g., X-App-Id: <app_id>"
        },
        status: :unauthorized
      )
    end

    # rubocop:enable Metrics/MethodLength

    def user_service_client
      @user_service_client ||= UserServiceClient.new
    end
end
