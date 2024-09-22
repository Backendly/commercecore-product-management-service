# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OrderItem, type: :model do
  describe 'validations' do
    context 'when the product and order belong to different apps' do
      let!(:product) { FactoryBot.create(:product, app_id: SecureRandom.uuid) }
      let!(:order) { FactoryBot.create(:order, app_id: SecureRandom.uuid) }

      it 'does not allow the order item to be created' do
        order_item = OrderItem.new(order:, product:)

        expect(order_item).not_to be_valid
        expect(order_item.errors[:base]).to include(
          'Product must belong to the same app as the order'
        )
      end
    end

    context 'when the product and order belong to the same app' do
      let!(:app_id) { SecureRandom.uuid }
      let!(:product) { FactoryBot.create(:product, app_id:) }
      let!(:order) { FactoryBot.create(:order, app_id:) }

      it 'allows the order item to be created' do
        order_item = OrderItem.new(
          order:, product:, price_at_purchase: 9.99,
          quantity: 1
        )

        expect(order_item).to be_valid
      end

      context 'when the purchase price is not set' do
        let!(:order_item) { FactoryBot.create(:order_item, order:, product:) }

        it 'does not allow the order item to be created' do
          order_item.price_at_purchase = nil

          expect(order_item).not_to be_valid
          expect(order_item.errors[:price_at_purchase]).to include(
            "can't be blank"
          )
        end
      end

      context 'when the quantity has problems' do
        it 'does not allow order item to be without quantity' do
          order_item = OrderItem.new(order:, product:, price_at_purchase: 9.99)
          order_item.quantity = nil

          expect(order_item).not_to be_valid
          expect(order_item.errors[:quantity]).to include(
            "can't be blank"
          )
        end

        it 'does not allow order item to be with negative quantity' do
          order_item = OrderItem.new(order:, product:, price_at_purchase: 9.99)
          order_item.quantity = -1

          expect(order_item).not_to be_valid
          expect(order_item.errors[:quantity]).to include(
            'must be greater than 0'
          )
        end
      end
    end

    context 'when the product_id is not provided' do
      let!(:order) { FactoryBot.create(:order) }

      it 'does not allow the order item to be created' do
        order_item = OrderItem.new(order:, price_at_purchase: 9.99, quantity: 1)

        expect(order_item).not_to be_valid
        expect(order_item.errors[:product_id]).to include(
          "can't be blank"
        )
      end
    end

    context 'when the order_id is not provided' do
      let!(:product) { FactoryBot.create(:product) }

      it 'does not allow the order item to be created' do
        order_item = OrderItem.new(product:, price_at_purchase: 9.99,
                                   quantity: 1)

        expect(order_item).not_to be_valid
        expect(order_item.errors[:order_id]).to include(
          "can't be blank"
        )
      end
    end
  end
end
