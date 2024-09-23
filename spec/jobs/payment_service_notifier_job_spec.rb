# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PaymentServiceNotifierJob, type: :job do
  describe '#perform' do
    let(:order) { FactoryBot.create(:order) }

    it 'calls OrderStatusNotificationJob.notify' do
      expect(OrderStatusNotificationJob).to receive(:notify).with(order)
      described_class.perform_now(order)
    end

    it 'calls #notify_payment_service' do
      expect_any_instance_of(described_class).to \
        receive(:notify_payment_service).with(order)
      described_class.perform_now(order)
    end
  end

  describe '.cancel_order' do
    let(:order) { FactoryBot.create(:order) }

    it 'calls perform' do
      expect_any_instance_of(described_class).to receive(:perform).with(order)
      described_class.cancel_order(order)
    end
  end

  describe '#notify_payment_service' do
    let(:order) { FactoryBot.create(:order) }
    let(:payment_service) { instance_double(Redis) }

    before do
      allow(Redis).to receive(:new).and_return(payment_service)
    end

    it 'publishes a message' do
      expect(payment_service).to receive(:publish).with(
        'payment_order_created', {
          order_id: order.id,
          user_id: order.user_id,
          app_id: order.app_id,
          total: order.total_amount,
          status: order.status,
          developer_id: order.developer_id
        }.to_json
      )

      described_class.new.send(:notify_payment_service, order)
    end
  end

  describe '#publish_channel' do
    let(:order) { FactoryBot.create(:order) }

    context 'when the order is created' do
      it 'returns the "payment_order_created" channel' do
        expect(described_class.new.send(:publish_channel, order)).to \
          eq('payment_order_created')
      end
    end

    context 'when the order is cancelled' do
      it 'returns the "payment_order_cancelled" channel' do
        order.update(status: 'cancelled')

        expect(described_class.new.send(:publish_channel, order)).to \
          eq('payment_order_cancelled')
      end
    end
  end
end
