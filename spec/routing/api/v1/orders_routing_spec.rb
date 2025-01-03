# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::V1::OrdersController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(get: "/api/v1/orders").to route_to(
        "api/v1/orders#index", format: :json,
      )
    end

    it "routes to #show" do
      expect(get: "/api/v1/orders/1").to route_to(
        "api/v1/orders#show",
        id: "1", format: :json,
      )
    end
  end
end
