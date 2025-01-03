# frozen_string_literal: true

require "rails_helper"
require "support/shared_contexts"

RSpec.describe "API::V1::CartItems", type: :request do
  include_context "common data"

  let(:user_id) { users.dig(:one, :id) }
  let(:developer_id) { developers.dig(:first, :id) }
  let(:app_id) { developers.dig(:first, :app_id) }

  let(:product) do
    FactoryBot.create(:product, developer_id:, app_id:, stock_quantity: 10)
  end

  describe "POST /create" do
    context "with authenticated user, valid App ID and Developer Token" do
      before do
        mock_authentication(
          controller_class: API::V1::CartItemsController,
          developer_id:,
          user_id:,
          app_id:,
        )
      end

      context "with valid params" do
        it "creates a new cart item" do
          post api_v1_cart_items_path,
               params: { cart_item: { product_id: product.id, quantity: 4 } },
               headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:created)
          expect(response_body.dig(:meta, :message)).to eq(
            "Cart item created successfully"
          )
        end

        context "when the quantity is more than the available products" do
          it "returns an error 422" do
            post api_v1_cart_items_path,
                 params: {
                   cart_item: {
                     product_id: product.id,
                     quantity: 11
                   }
                 },
                 headers: valid_headers[:first_dev]

            expect(response).to have_http_status(:unprocessable_content)
            expect(response_body.dig(:details, :quantity)).to include(
              "must be less than or equal to the stock"
            )
          end
        end

        it "updates an existing cart item" do
          # create a new cart item first with a quantity of 4
          post api_v1_cart_items_path,
               params: { cart_item: { product_id: product.id, quantity: 4 } },
               headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:created)
          expect(response_body.dig(:meta, :message)).to eq(
            "Cart item created successfully"
          )

          # update the cart item with a new quantity of 6
          post api_v1_cart_items_path,
               params: { cart_item: { product_id: product.id, quantity: 6 } },
               headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:ok)
          expect(response_body.dig(:meta, :message)).to eq(
            "Cart item updated successfully"
          )
        end
      end

      context "with invalid params" do
        it "returns an error 422 when quantity is missing" do
          post api_v1_cart_items_path,
               params: { cart_item: { product_id: product.id } },
               headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:unprocessable_content)
          expect(response_body.dig(:details, :quantity)).to include(
            "can't be blank"
          )
        end

        it "returns an error 422 when product ID is missing" do
          post api_v1_cart_items_path,
               params: { cart_item: { quantity: 4 } },
               headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:unprocessable_content)
          expect(response_body.dig(:details, :product_id)).to eq(
            "must be provided"
          )
        end

        it "fails when product does not exist" do
          post api_v1_cart_items_path,
               params: { cart_item: { product_id: "invalid", quantity: 4 } },
               headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:unprocessable_content)
          expect(response_body.dig(:details, :product)).to eq("must exist")
        end

        it "fails when product is not associated with the app" do
          product.update!(app_id: UUID7.generate)

          post api_v1_cart_items_path,
               params: { cart_item: { product_id: product.id, quantity: 4 } },
               headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:unprocessable_content)
          expect(response_body.dig(:details, :product)).to eq(
            "must be associated with the app"
          )
        end
      end
    end
  end

  describe "DELETE /destroy" do
    context "with authenticated user, valid App ID and Developer Token" do
      before do
        mock_authentication(
          controller_class: API::V1::CartItemsController,
          developer_id:,
          user_id:,
          app_id:,
        )
      end

      context "with valid params" do
        it "deletes a cart item" do
          # create a new cart item first
          post api_v1_cart_items_path,
               params: { cart_item: { product_id: product.id, quantity: 4 } },
               headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:created)

          item = CartItem.find(response_body.dig(:data, :id))

          # delete the cart item
          delete api_v1_cart_item_path(item.id),
                 headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:no_content)
          expect(CartItem.find_by(id: item.id)).to be_nil
        end
      end

      context "with invalid params" do
        it "returns an error 404 when cart item does not exist" do
          delete api_v1_cart_item_path("invalid"),
                 headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:not_found)
          expect(response_body[:error]).to eq("CartItem not found")
        end
      end
    end
  end

  describe "GET /show" do
    context "with authenticated user, valid App ID and Developer Token" do
      before do
        mock_authentication(
          controller_class: API::V1::CartItemsController,
          developer_id:,
          user_id:,
          app_id:,
        )
      end

      context "with valid params" do
        it "returns a cart item" do
          # create a new cart item first
          post api_v1_cart_items_path,
               params: { cart_item: { product_id: product.id, quantity: 4 } },
               headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:created)

          item = CartItem.find(response_body.dig(:data, :id))

          get api_v1_cart_item_path(item.id),
              headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:ok)
          expect(response_body.dig(:data, :id)).to eq(item.id)
        end
      end

      context "with invalid params" do
        it "returns an error 404 when cart item does not exist" do
          get api_v1_cart_item_path("invalid"),
              headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:not_found)
          expect(response_body[:error]).to eq("CartItem not found")
        end
      end
    end
  end

  describe "GET /index" do
    context "with authenticated user, valid App ID and Developer Token" do
      before do
        mock_authentication(
          controller_class: API::V1::CartItemsController,
          developer_id:,
          user_id:,
          app_id:,
        )
      end

      context "with valid params" do
        it "returns a list of cart items" do
          # create a new cart item first
          post api_v1_cart_items_path,
               params: { cart_item: { product_id: product.id, quantity: 4 } },
               headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:created)

          get api_v1_cart_items_path,
              headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:ok)
          expect(response_body[:data].size).to eq(1)
        end
      end
    end
  end
end
