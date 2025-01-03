# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API::V1::Roots", type: :request do
  describe "GET /index" do
    it "returns a welcome message and a list of available endpoints" do
      get "/api/v1"
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        "Welcome to the Product Management Service API"
      )
      expect(response.body).to include("v1")
      expect(response.body).to include(
        "https://documenter.getpostman.com/view/14404907/2sAXjRWpnZ"
      )
      expect(response.body).to include("/api/v1/products")
      expect(response.body).to include("/api/v1/categories")
      expect(response.body).to include("/api/v1/cart")
      expect(response.body).to include("/api/v1/orders")
      expect(response.body).to include("/api/v1/status")
    end

    it "has the correct base_url" do
      get "/api/v1"
      expect(response).to have_http_status(:ok)
      expect(response_body[:base_url]).to eq("http://www.example.com/api/v1")
    end

    it "returns the correct version" do
      get "/api/v1"
      expect(response).to have_http_status(:ok)
      expect(response_body[:version]).to eq("v1")
    end

    it "returns the correct documentation link" do
      get "/api/v1"
      expect(response).to have_http_status(:ok)
      expect(response_body[:documentation]).to eq(
        "https://documenter.getpostman.com/view/14404907/2sAXjRWpnZ"
      )
    end
  end

  context "when the root endpoint is accessed" do
    it "redirects to /api/v1" do
      get "/"
      expect(response).to redirect_to("/api/v1")
    end
  end
end
