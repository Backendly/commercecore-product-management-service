# frozen_string_literal: true

module RequestsHelper
  def response_body
    JSON.parse(response.body, symbolize_names: true)
  end
end
