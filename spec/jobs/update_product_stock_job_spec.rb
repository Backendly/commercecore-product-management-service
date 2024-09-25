# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateProductStockJob, type: :job do
  describe '#perform' do
    let!(:app_id) { UUID7.generate }
    let!(:product) { FactoryBot.create(:product, app_id:, stock_quantity: 10) }
    let!(:order) { FactoryBot.create(:order, app_id:) }

    context 'when the order is successful' do
      before do
        order.update(status: 'successful')
      end
      context 'when the order has one item' do
        let!(:order_item) do
          FactoryBot.create(:order_item, order:, product:, quantity: 1)
        end

        it 'updates the product stock' do
          expect do
            described_class.perform_now(order.id)
          end.to change { product.reload.stock_quantity }.from(10).to(9)
        end
      end

      context 'when the order has multiple items' do
        let!(:product2) do
          FactoryBot.create(:product, app_id:, stock_quantity: 10)
        end

        let!(:order_item1) do
          FactoryBot.create(:order_item, order:, product:, quantity: 1)
        end

        let!(:order_item2) do
          FactoryBot.create(:order_item, order:, product: product2,
                                         quantity: 2)
        end

        it 'updates the product stock' do
          expect do
            described_class.perform_now(order.id)
          end.to change {
            product.reload.stock_quantity
          }.from(10).to(9).and change {
            product2.reload.stock_quantity
          }.from(10).to(8)
        end
      end
    end

    context 'when the order is not successful' do
      before do
        order.update(status: 'failed')
      end

      it 'does not update the product stock' do
        expect do
          described_class.perform_now(order.id)
        end.not_to(change { product.reload.stock_quantity })
      end
    end

    context 'when the order is not found' do
      it 'logs an error message' do
        expect(Rails.logger).to receive(:error).with(
          'Order with ID invalid_id not found'
        )

        described_class.perform_now('invalid_id')
      end
    end

    context 'when the order is refunded' do
      before do
        order.update(status: 'successful')
      end

      let!(:order_item) do
        FactoryBot.create(:order_item, order:, product:, quantity: 1)
      end

      it 'restores the product stock' do
        expect do
          described_class.perform_now(order.id, status: 'refunded')
        end.to change { product.reload.stock_quantity }.from(10).to(11)
      end
    end
  end
end
