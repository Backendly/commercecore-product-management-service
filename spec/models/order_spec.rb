# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Order, type: :model do
  let!(:product) { FactoryBot.create(:product) }
  let!(:order) do
    Order.create!(
      user_id: UUID7.generate,
      developer_id: product.developer_id,
      app_id: product.app_id,
      total_amount: 9.99
    )
  end
  let!(:order_item) { FactoryBot.create(:order_item, order:, product:) }

  context 'during creation' do
    it 'fails when the order status is set to anything other than pending' do
      expect do
        Order.create!(
          user_id: UUID7.generate,
          developer_id: UUID7.generate,
          app_id: UUID7.generate,
          total_amount: 9.99,
          status: 'successful'
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'fails when the total amount is not set' do
      expect do
        Order.create!(
          user_id: UUID7.generate,
          developer_id: UUID7.generate,
          app_id: UUID7.generate,
          status: 'pending'
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'fails when the total amount is set to a negative value' do
      expect do
        Order.create!(
          user_id: UUID7.generate,
          developer_id: UUID7.generate,
          app_id: UUID7.generate,
          total_amount: -9.99,
          status: 'pending'
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'fails when the total amount is set to a non-numeric value' do
      expect do
        Order.create!(
          user_id: UUID7.generate,
          developer_id: UUID7.generate,
          app_id: UUID7.generate,
          total_amount: 'nine',
          status: 'pending'
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'fails when the user_id is not set' do
      expect do
        Order.create!(
          developer_id: UUID7.generate,
          app_id: UUID7.generate,
          total_amount: 9.99,
          status: 'pending'
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'fails when the developer_id is not set' do
      expect do
        Order.create!(
          user_id: UUID7.generate,
          app_id: UUID7.generate,
          total_amount: 9.99
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'fails when the app_id is not set' do
      expect do
        Order.create!(
          user_id: UUID7.generate,
          developer_id: UUID7.generate,
          total_amount: 9.99
        )
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    context 'when there is a pending order for the user' do
      it 'fails to create a new order' do
        expect do
          Order.create!(
            user_id: order.user_id,
            developer_id: order.developer_id,
            app_id: order.developer_id,
            total_amount: 9.99,
            status: 'pending'
          )
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  context 'after creation' do
    it 'sets the order status to pending by default' do
      expect(order.status).to eq('pending')
    end

    it 'can set the order status to successful' do
      expect do
        order.update!(status: 'successful')
      end.to change { order.status }.from('pending').to('successful')
    end

    it 'can set the order status to failed' do
      expect do
        order.update!(status: 'failed')
      end.to change { order.status }.from('pending').to('failed')
    end
  end

  describe 'deletions' do
    it 'deletes an order' do
      expect do
        order.destroy
      end.to change { Order.count }.by(-1)
    end

    it 'deletes an order by id' do
      expect do
        Order.destroy(order.id)
      end.to change { Order.count }.by(-1)
    end

    it 'throws an error for non-existent order' do
      expect do
        Order.destroy(UUID7.generate)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    context 'when order items are available' do
      it 'deletes related order items' do
        expect(order.order_items.first).to eq(order_item)

        expect do
          order.destroy
        end.to change { order.order_items.count }.by(-1)
      end
    end
  end
end
