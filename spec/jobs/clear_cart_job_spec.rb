# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClearCartJob, type: :job do
  describe '#perform' do
    let!(:product) { FactoryBot.create(:product, app_id: UUID7.generate) }
    let!(:cart) { FactoryBot.create(:cart, app_id: product.app_id) }
    let!(:cart_item) { FactoryBot.create(:cart_item, cart:) }

    context 'when the correct user ID is provided' do
      it 'clears the cart' do
        expect do
          described_class.perform_now(cart.user_id)
        end.to change { cart.cart_items.count }.from(1).to(0)
      end
    end

    context 'when the user ID is incorrect' do
      it 'does not clear the cart' do
        expect do
          described_class.perform_now('invalid-user-id')
        end.not_to(change { cart.cart_items.count })
      end

      it 'logs an error' do
        expect(Rails.logger).to \
          receive(:error).with('No cart found for user_id: invalid-user-id')
        described_class.perform_now('invalid-user-id')
      end
    end
  end
end
