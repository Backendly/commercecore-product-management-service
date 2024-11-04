# frozen_string_literal: true

# Service class to handle API requests to the user service and manage caching.
class UserServiceClient
  include HTTParty
  base_uri ENV["USER_SERVICE_URL"]

  # rubocop:disable Metrics/MethodLength

  # Fetches and caches the developer data based on the developer token.
  #
  # @param developer_token [String] the developer token to validate
  # @return [String, nil] the developer ID if valid, nil otherwise
  def fetch_developer_id(developer_token:)
    dev_token_key = "developer:#{developer_token}"
    cached_data = Rails.cache.fetch(dev_token_key)

    return cached_data if cached_data

    response = self.class.get(
      "/developer/validate-token",
      headers: { "X-API-Token" => developer_token }
    )

    if response.success?
      Rails.cache.fetch(dev_token_key, expires_in: 12.hours) do
        response.parsed_response.dig("developer", "id")
      end
    else
      Rails.logger.error "Failed to validate developer token: " \
        "#{developer_token}"
      nil
    end
  end

  # Fetches and caches the user data based on the user ID.
  #
  # @param user_id [String] the user ID to validate
  # @param app_id [String] the app ID to validate
  # @param developer_token [String] the developer token to validate
  # @return [Hash, nil] the user data if valid, nil otherwise
  def fetch_user(user_id:, app_id:, developer_token:)
    cache_key = "user:#{user_id}_app:#{app_id}_dev:#{developer_token}"
    cached_data = Rails.cache.fetch(cache_key)

    return cached_data if cached_data

    response = self.class.get(
      "/user/validate-user/#{user_id}", headers: {
      "X-API-Token" => developer_token,
      "X-App-Id" => app_id
      }
    )

    if response.success?
      Rails.cache.fetch(cache_key, expires_in: 12.hours) do
        response.parsed_response
      end
    else
      Rails.logger.error "Failed to validate user: " \
        "#{user_id} for app: #{app_id}"

      nil
    end
  end

  # Fetches and caches the app data based on the app ID.
  #
  # @param app_id [String] the app ID to validate
  # @param developer_token [String] the developer token to validate
  # @return [Hash, nil] the app data if valid, nil otherwise
  def fetch_app(app_id:, developer_token:)
    cache_key = "app:#{app_id}_#{developer_token}"
    cached_data = Rails.cache.fetch(cache_key)

    return cached_data if cached_data

    response = self.class.get(
      "/app/validate-app/#{app_id}", headers: {
      "X-API-Token" => developer_token
      }
    )

    if response.success?
      Rails.cache.fetch(cache_key, expires_in: 12.hours) do
        response.parsed_response
      end
    else
      Rails.logger.error "Failed to validate app: " \
        "#{app_id} for developer: #{developer_token}"
      nil
    end
  end
end

# rubocop:enable Metrics/MethodLength
