# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_contexts'

RSpec.describe "Api::V1::Orders", type: :request do
  include_context 'common data'

  before do
    mock_authentication(controller_class: Api::V1::OrdersController)
  end

  describe 'Endpoints' do
    before do
      @app_id = developers.dig(:first, :app_id)
      @user_id = users.dig(:one, :id)
      @developer_id = developers.dig(:first, :id)

      products = FactoryBot.create_list(:product, 10, app_id: @app_id)

      cart = FactoryBot.create(:cart, app_id: @app_id, user_id: @user_id,
                                      developer_id: @developer_id)

      products.each do |product|
        FactoryBot.create(:cart_item, cart:, product:)
      end

      mock_authentication(
        controller_class: Api::V1::OrdersController,
        app_id: @app_id,
        developer_id: @developer_id,
        user_id: @user_id
      )
    end

    describe "GET /api/v1/orders" do
      context 'when no orders has been placed' do
        it 'returns a successful response with an empty data' do
          get api_v1_orders_path, headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:ok)
          expect(response_body[:data]).to be_empty
        end
      end

      context 'when at least one order has been placed' do
        before do
          # checkout
          post checkout_api_v1_cart_path, headers: valid_headers[:first_dev]
          expect(response).to have_http_status(:created)

          @order = Order.last
        end

        it "returns a success response" do
          get api_v1_orders_path, headers: valid_headers[:first_dev]
          expect(response).to have_http_status(200)
        end

        it 'has some data in the JSON response' do
          get api_v1_orders_path, headers: valid_headers[:first_dev]

          expect(response_body[:data]).to_not be_empty
        end

        describe 'ordering' do
          context 'when the "asc" query parameter is specified' do
            it 'returns the orders in ascending order' do
              get api_v1_orders_path, headers: valid_headers[:first_dev],
                                      params: { order: 'asc' }

              expect(response).to have_http_status(:ok)
              data = response_body[:data]
              expect(data.first[:id]).to eq(@order.id)
            end
          end
        end

        describe 'filtering' do
          context 'when filtered by orders with available entries' do
            %w[pending cancelled processing successful
               failed].each do |status|
              it "returns only orders with the status: #{status}" do
                @order.update(status:)

                get api_v1_orders_path, headers: valid_headers[:first_dev],
                                        params: { status: }

                expect(response).to have_http_status(:ok)
                data = response_body[:data].first
                expect(data.dig(:attributes, :status)).to eq(status)
              end
            end
          end

          context 'when no pending orders are available' do
            it 'returns an empty data' do
              @order.update(status: 'processing')
              get api_v1_orders_path, headers: valid_headers[:first_dev],
                                      params: { status: 'pending' }

              expect(response).to have_http_status(:ok)
              expect(response_body[:data]).to be_empty
            end
          end
        end

        describe 'response body' do
          before do
            get api_v1_orders_path, headers: valid_headers[:first_dev]
            @data = response_body[:data].first
          end

          it 'returns the order details' do
            expect(@data[:id]).to eq(@order.id)
            expect(@data[:type]).to eq('order')
            expect(@data.dig(:attributes, :status)).to eq(@order.status)
            expect(@data.dig(:attributes, :total_amount)).to eq(
              @order.total_amount.to_s
            )
            expect(@data.dig(:attributes, :created_at)).to eq(
              @order.created_at.iso8601(3)
            )
            expect(@data.dig(:attributes, :updated_at)).to eq(
              @order.updated_at.iso8601(3)
            )
          end

          it 'returns the order links' do
            expect(@data[:links][:self]).to eq(
              api_v1_order_url(@order, host: 'test-server.com')
            )
            expect(@data[:links][:related]).to eq(
              api_v1_order_items_url(@order, host: 'test-server.com')
            )
          end
        end
      end
    end

    describe 'GET /api/v1/orders/:id' do
      context 'when the order does not exist' do
        it 'returns a not found response' do
          get api_v1_order_path(UUID7.generate),
              headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when the order exists' do
        before do
          # checkout
          post checkout_api_v1_cart_path, headers: valid_headers[:first_dev]
          expect(response).to have_http_status(:created)

          @order = Order.last
        end

        it 'returns a success response' do
          get api_v1_order_path(@order.id), headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:ok)
        end

        it 'has some data in the JSON response' do
          get api_v1_order_path(@order.id), headers: valid_headers[:first_dev]

          expect(response_body[:data]).to_not be_empty
        end
      end
    end

    describe 'POST /api/v1/orders/:id/cancel' do
      context 'when the order does not exist' do
        it 'returns a not found response' do
          post cancel_api_v1_order_path(UUID7.generate),
               headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:not_found)
        end
      end

      context 'when the order exists' do
        before do
          # checkout
          post checkout_api_v1_cart_path, headers: valid_headers[:first_dev]
          expect(response).to have_http_status(:created)

          @order = Order.last
        end

        context 'when the order is pending' do
          it 'returns a success response' do
            post cancel_api_v1_order_path(@order.id),
                 headers: valid_headers[:first_dev]

            expect(response).to have_http_status(:ok)
          end

          it 'returns a success message' do
            post cancel_api_v1_order_path(@order.id),
                 headers: valid_headers[:first_dev]

            expect(response_body[:message]).to eq(
              'Order cancelled successfully'
            )
          end

          it 'publishes a message to the payment service' do
            expect(PaymentServiceNotifierJob).to receive(:cancel_order)
              .with(@order)

            post cancel_api_v1_order_path(@order.id),
                 headers: valid_headers[:first_dev]
          end
        end

        context 'when the order is not pending' do
          it 'returns a bad request response' do
            @order.update(status: 'processing')

            post cancel_api_v1_order_path(@order.id),
                 headers: valid_headers[:first_dev]

            expect(response).to have_http_status(:bad_request)
          end
        end
      end
    end
  end
end
