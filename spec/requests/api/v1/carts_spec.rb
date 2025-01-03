# frozen_string_literal: true

require "rails_helper"
require "support/shared_contexts"

RSpec.describe "API::V1::Carts", type: :request do
  include_context "common data"

  before do
    mock_authentication(controller_class: API::V1::CartsController)
  end

  let(:user_id) { users.dig(:one, :id) }
  let(:developer_id) { developers.dig(:first, :id) }
  let(:app_id) { developers.dig(:first, :app_id) }

  let(:cart) do
    FactoryBot.create(:cart, user_id:, app_id:, developer_id:)
  end

  describe "GET /show" do
    context "when creating a new cart" do
      context "with authenticated user, valid developer and app" do
        before do
          mock_authentication(
            controller_class: API::V1::CartsController,
            developer_id:,
            user_id:,
            app_id:,
          )
        end

        it "uses the header fields to set the user_id, developer_id, " \
           "and app_id" do
          get api_v1_cart_path, headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:ok)

          cart = Cart.find_by(user_id:, developer_id:, app_id:)
          expect(cart).to be_present
        end

        context "multiple requests with the same user information" do
          it "returns the existing cart instead of creating a duplicate" do
            expect do
              get api_v1_cart_path, headers: valid_headers[:first_dev]
            end.to change { Cart.count }.by(1)

            expect(response).to have_http_status(:ok)

            # on second try, it should simply return the previous item
            expect do
              get api_v1_cart_path, headers: valid_headers[:first_dev]
            end.to_not(change { Cart.count })

            expect(response).to have_http_status(:ok)
          end

          it "has the same details as the previously created cart" do
            get api_v1_cart_path, headers: valid_headers[:first_dev]

            cart = Cart.find_by(user_id:, app_id:)

            get api_v1_cart_path, headers: valid_headers[:first_dev]
            expect(response_body.dig(:data, :id)).to eq(cart.id)
            expect(response_body.dig(:data, :attributes, :user_id)).to \
              eq(user_id)
            expect(response_body.dig(:data, :attributes, :app_id)).to eq(app_id)
            expect(response_body.dig(:data, :attributes, :developer_id)).to \
              eq(developer_id)
          end

          it "has the same timestamp" do
            get api_v1_cart_path, headers: valid_headers[:first_dev]

            cart = Cart.find_by(user_id:, app_id:)

            get api_v1_cart_path, headers: valid_headers[:first_dev]
            expect(response_body.dig(:data, :attributes, :created_at)).to \
              eq(cart.created_at.iso8601(3))
          end
        end

        it "returns the created cart" do
          get api_v1_cart_path, headers: valid_headers[:first_dev]

          cart = Cart.find_by(user_id:, app_id:)
          expect(response_body.dig(:data, :id)).to eq(cart.id)
        end

        describe "response body" do
          it "includes the cart attributes" do
            get api_v1_cart_path, headers: valid_headers[:first_dev]

            expect(response_body.dig(:data, :attributes, :user_id)).to \
              eq(user_id)
            expect(response_body.dig(:data, :attributes, :developer_id)).to \
              eq(developer_id)
            expect(response_body.dig(:data, :attributes, :app_id)).to eq(app_id)
          end

          it "includes the cart creation timestamp" do
            get api_v1_cart_path, headers: valid_headers[:first_dev]

            expect(response_body.dig(:data, :attributes, :created_at)).to \
              be_present
          end

          it "includes a message indicating the cart was retrieved" do
            get api_v1_cart_path, headers: valid_headers[:first_dev]

            expect(response_body.dig(:meta, :message)).to \
              eq("Cart retrieved successfully")
          end
        end
      end
    end

    describe "unauthorized actions" do
      context "without authentication" do
        it "returns 401 Unauthorized" do
          get api_v1_cart_path

          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "with invalid developer" do
        it "returns 401 Unauthorized" do
          get api_v1_cart_path, headers: {
                                  "X-User-Id" => SecureRandom.uuid,
                                  "X-Developer-Token" => "invalid",
                                  "X-App-Id" => SecureRandom.uuid
                                }

          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "when the app_id is not provided" do
        it "returns 401 Unauthorized" do
          get api_v1_cart_path, headers: {
                                  "X-User-Id" => SecureRandom.uuid,
                                  "X-Developer-Token" => SecureRandom.uuid
                                }

          expect(response).to have_http_status(:unauthorized)
        end
      end

      context "when the user_id is not provided" do
        it "returns 401 Unauthorized" do
          get api_v1_cart_path, headers: {
                                  "X-Developer-Token" => SecureRandom.uuid,
                                  "X-App-Id" => SecureRandom.uuid
                                }
        end
      end

      context "when the developer_id is not provided" do
        it "returns 401 Unauthorized" do
          get api_v1_cart_path, headers: {
                                  "X-User-Id" => SecureRandom.uuid,
                                  "X-App-Id" => SecureRandom.uuid
                                }

          expect(response).to have_http_status(:unauthorized)
        end
      end
    end
  end
end
