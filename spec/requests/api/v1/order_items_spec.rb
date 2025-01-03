# frozen_string_literal: true

require "rails_helper"
require "support/shared_contexts"

RSpec.describe "API::V1::OrderItems", type: :request do
  include_context "common data"

  before do
    mock_authentication(controller_class: API::V1::OrderItemsController)
  end

  let!(:user_id) { users.dig(:one, :id) }
  let!(:app_id) { developers.dig(:first, :app_id) }
  let!(:cart) { FactoryBot.create(:cart, user_id:, app_id:) }
  let!(:products) { FactoryBot.create_list(:product, 10, app_id:) }
  let!(:order) { FactoryBot.create(:order, user_id:, app_id:) }
  let!(:order_items) do
    products.map do |product|
      FactoryBot.create(:order_item, order:, product:)
    end
  end
  let!(:order_item) { order_items.first }

  context "with authenticated user" do
    before do
      mock_authentication(
        controller_class: API::V1::OrderItemsController,
        app_id:,
        user_id:,
        developer_id: developers.dig(:first, :id),
      )
    end

    describe "GET /api/v1/orders/:order_id/order_items" do
      before do
        get api_v1_order_items_path(order), headers: valid_headers[:first_dev]
      end
      context "when the order exists" do
        it "returns http success" do
          expect(response).to have_http_status(:success)
        end

        it "returns the correct number of order items" do
          expect(response_body[:data].size).to eq(order_items.size)
        end
      end

      context "when the order is not found" do
        before do
          get api_v1_order_items_path(UUID7.generate),
              headers: valid_headers[:first_dev]
        end

        it "returns http not found" do
          expect(response).to have_http_status(:not_found)
        end

        it "returns an error message" do
          expect(response_body[:error]).to eq("Order not found")
        end
      end
    end

    describe "GET /api/v1/orders/:order_id/order_items/:id" do
      context "when the order and the order items are found" do
        before do
          get api_v1_order_item_path(order, order_item),
              headers: valid_headers[:first_dev]
        end

        it "returns http success" do
          expect(response).to have_http_status(:success)
        end

        it "returns the correct order item" do
          expect(response_body[:data][:id]).to eq(order_item.id)
        end
      end

      context "when the order item is not found" do
        before do
          get api_v1_order_item_path(order, UUID7.generate),
              headers: valid_headers[:first_dev]
        end

        it "returns http not found" do
          expect(response).to have_http_status(:not_found)
        end

        it "returns an error message" do
          expect(response_body[:error]).to eq("OrderItem not found")
        end
      end

      context "when the order is not found" do
        before do
          get api_v1_order_item_path(UUID7.generate, order_item),
              headers: valid_headers[:first_dev]
        end

        it "returns http not found" do
          expect(response).to have_http_status(:not_found)
        end

        it "returns an error message" do
          expect(response_body[:error]).to eq("Order not found")
        end
      end
    end
  end
end
