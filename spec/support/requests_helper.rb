# frozen_string_literal: true

module RequestsHelper
  def response_body
    JSON.parse(response.body, symbolize_names: true)
  end

  # An authentication mocking helper for controller request testing
  def authenticate_headers(headers, valid_dev_token: false,
                           valid_user_id: false, valid_app_id: false) end
end
