# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UpdateOrderStatusJob, type: :job do
  describe '#perform' do
    let(:order) { FactoryBot.create(:order) }
    let(:bad_order_id) { UUID7.generate }
    let(:status) { 'successful' }

    it 'updates the order status' do
      expect { described_class.perform_now(order.id, status) }
        .to change { order.reload.status }.from('pending').to(status)
    end

    context 'when the order does not exist' do
      it 'logs an error' do
        expect(Rails.logger).to \
          receive(:error).with("Order with ID #{bad_order_id} not found")
        described_class.perform_now(bad_order_id, status)
      end
    end
  end
end
