# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_contexts'

RSpec.describe "Api::V1::Checkout", type: :request do
  include_context 'common data'

  before do
    mock_authentication(controller_class: Api::V1::CheckoutController)
  end

  describe "POST /api/v1/cart/checkout" do
    before do
      mock_authentication(
        controller_class: Api::V1::CheckoutController,
        user_id: users.dig(:one, :id),
        app_id: developers.dig(:first, :app_id),
        developer_id: developers.dig(:first, :id)
      )
    end

    context "when the cart is empty" do
      it "returns an error" do
        post checkout_api_v1_cart_path, headers: valid_headers[:first_dev]

        expect(response).to have_http_status(:unprocessable_content)
        expect(response_body[:error]).to eq("Cart is empty or does not exist")
      end
    end

    context "when the cart has items" do
      let!(:products) do
        FactoryBot.create_list(
          :product, 10,
          app_id: developers.dig(:first, :app_id)
        )
      end
      let!(:product) { products.first }

      let!(:cart) do
        FactoryBot.create(
          :cart, app_id: product.app_id,
                 user_id: users.dig(:one, :id)
        )
      end
      let!(:more) do
        products.each do |product|
          FactoryBot.create(
            :cart_item, cart:, product:
          )
        end
      end
      let!(:cart_items) { CartItem.all }

      it "creates an order" do
        post checkout_api_v1_cart_path, headers: valid_headers[:first_dev]

        expect(response).to have_http_status(:created)
      end

      it 'the type of the object is an order' do
        post checkout_api_v1_cart_path, headers: valid_headers[:first_dev]

        expect(response_body.dig(:data, :type)).to eq("order")
      end

      it "moves cart items to the order" do
        post checkout_api_v1_cart_path, headers: valid_headers[:first_dev]

        expect(response).to have_http_status(:created)

        expect(response_body.dig(:data, :type)).to eq("order")
        expect(OrderItem.count).to eq(cart_items.count)
        expect(OrderItem.first.order_id).to eq(response_body.dig(:data, :id))
      end

      it "has a default status of 'pending'" do
        post checkout_api_v1_cart_path, headers: valid_headers[:first_dev]

        expect(response_body.dig(:data, :attributes, :status)).to eq('pending')
      end

      context 'when the cart items are moved to the order' do
        it 'has the same number items in the cart item' do
          post checkout_api_v1_cart_path, headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:created)
          expect(response_body.dig(
            :data, :relationships, :order_items, :data
          ).count).to eq(cart_items.count)
        end

        it 'has the same information as the cart items' do
          post checkout_api_v1_cart_path, headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:created)

          order_items = response_body.dig(
            :data, :relationships, :order_items, :data
          )

          order_items.each_with_index do |order_item, index|
            cart_item = cart_items[index]
            item = OrderItem.find(order_item[:id])

            expect(item.product_id).to eq(cart_item.product_id)
            expect(item.quantity).to eq(cart_item.quantity)
            expect(item.price_at_purchase).to eq(cart_item.product.price)
          end
        end
      end

      it "calculates the total amount for the order" do
        post checkout_api_v1_cart_path, headers: valid_headers[:first_dev]

        expect(response).to have_http_status(:created)
        expect(response_body.dig(:data, :attributes, :total_amount).to_f).to eq(
          cart_items.sum { |item| item.quantity * item.product.price }.to_f
        )
      end

      it 'notifies the payment service' do
        expect(PaymentServiceNotifierJob).to \
          receive(:perform_later).and_call_original

        post checkout_api_v1_cart_path, headers: valid_headers[:first_dev]
      end

      context 'when the user has a pending order' do
        it 'returns an error' do
          post checkout_api_v1_cart_path, headers: valid_headers[:first_dev]

          # the first call successful creates the order
          expect(response).to have_http_status(:created)

          # the second call returns an error
          post checkout_api_v1_cart_path, headers: valid_headers[:first_dev]

          expect(response).to have_http_status(:payment_required)
          expect(response_body[:error]).to eq(
            'You already have an order in a pending state'
          )
        end
      end
    end
  end
end
