# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::V1::CategoriesController, type: :routing do
  let(:developer_id) { UUID7.generate }

  describe "routing" do
    it "routes to #index" do
      expect(get: "/api/v1/categories").to route_to("api/v1/categories#index")
    end

    it "routes to #show" do
      expect(get: "/api/v1/categories/#{developer_id}").to route_to(
        "api/v1/categories#show",
        id: developer_id,
      )
    end

    it "routes to #create" do
      expect(post: "/api/v1/categories").to route_to("api/v1/categories#create")
    end

    it "routes to #update via PUT" do
      expect(put: "/api/v1/categories/#{developer_id}").to route_to(
        "api/v1/categories#update", id: developer_id,
      )
    end

    it "routes to #update via PATCH" do
      expect(patch: "/api/v1/categories/#{developer_id}").to route_to(
        "api/v1/categories#update", id: developer_id,
      )
    end

    it "routes to #destroy" do
      expect(delete: "/api/v1/categories/#{developer_id}").to route_to(
        "api/v1/categories#destroy", id: developer_id,
      )
    end
  end
end
