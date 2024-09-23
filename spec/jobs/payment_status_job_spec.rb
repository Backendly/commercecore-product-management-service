# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentStatusJob, type: :job do
  describe '#perform' do
    let(:order) { FactoryBot.create(:order) }

    context 'when status is succeeded' do
      it 'calls UpdateProductStockJob' do
        expect(UpdateProductStockJob).to receive(:perform_later).with(order.id)
        described_class.perform_now(order.id, 'succeeded')
      end

      it 'calls ClearCartJob' do
        expect(ClearCartJob).to receive(:perform_later).with(order.user_id)
        described_class.perform_now(order.id, 'succeeded')
      end

      it 'calls UpdateOrderStatusJob' do
        expect(UpdateOrderStatusJob).to \
          receive(:perform_later).with(order.id, 'successful')
        described_class.perform_now(order.id, 'succeeded')
      end

      it 'calls NotifyUserServiceJob' do
        expect(NotifyUserServiceJob).to \
          receive(:perform_later).with(order.id, 'successful')
        described_class.perform_now(order.id, 'succeeded')
      end
    end

    context 'when status is created' do
      it 'calls UpdateOrderStatusJob' do
        expect(UpdateOrderStatusJob).to \
          receive(:perform_later).with(order.id, 'processing')
        described_class.perform_now(order.id, 'created')
      end
    end

    context 'when status fail' do
      it 'calls UpdateOrderStatusJob' do
        expect(UpdateOrderStatusJob).to \
          receive(:perform_later).with(order.id, 'failed')
        described_class.perform_now(order.id, 'failed')
      end

      it 'calls NotifyUserServiceJob' do
        expect(NotifyUserServiceJob).to \
          receive(:perform_later).with(order.id, 'failed')
        described_class.perform_now(order.id, 'failed')
      end
    end

    it 'calls OrderStatusNotificationJob.notify' do
      expect(OrderStatusNotificationJob).to receive(:notify).with(order)
      described_class.perform_now(order.id, 'succeeded')
    end
  end
end
