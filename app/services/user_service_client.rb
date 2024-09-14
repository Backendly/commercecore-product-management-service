# frozen_string_literal: true

# Service class to handle API requests to the user service and manage caching.
class UserServiceClient
  include HTTParty
  base_uri ENV['USER_SERVICE_URL']

  # rubocop:disable Metrics/MethodLength

  # Fetches and caches the developer data based on the developer token.
  #
  # @param developer_token [String] the developer token to validate
  # @return [String, nil] the developer ID if valid, nil otherwise
  def fetch_developer_id(developer_token)
    dev_token_key = "developer:#{developer_token}"
    cached_data = Rails.cache.fetch(dev_token_key)
    return cached_data if cached_data

    response = self.class.get(
      '/validate_developer',
      headers: { 'X-Developer-Token' => developer_token }
    )

    return unless response.success?

    Rails.cache.fetch(dev_token_key, expires_in: 12.hours) do
      response.parsed_response['developer_id']
    end
  end

  # rubocop:enable Metrics/MethodLength

  # Fetches and caches the user data based on the user ID.
  #
  # @param user_id [String] the user ID to validate
  # @return [Hash, nil] the user data if valid, nil otherwise
  def fetch_user(user_id)
    Rails.cache.fetch("user:#{user_id}", expires_in: 12.hours) do
      response = self.class.get("/validate_user/#{user_id}")
      return response.parsed_response if response.success?

      nil
    end
  end

  # Fetches and caches the app data based on the app ID.
  #
  # @param app_id [String] the app ID to validate
  # @return [Hash, nil] the app data if valid, nil otherwise
  def fetch_app(app_id)
    Rails.cache.fetch("app:#{app_id}", expires_in: 12.hours) do
      response = self.class.get("/validate_app/#{app_id}")
      return response.parsed_response if response.success?

      nil
    end
  end
end
