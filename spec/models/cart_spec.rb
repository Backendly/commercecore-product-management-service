# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cart, type: :model do
  let(:developer_id) { SecureRandom.uuid }
  let(:user_id) { SecureRandom.uuid }
  let(:app_id) { SecureRandom.uuid }

  let!(:cart) { FactoryBot.create(:cart, developer_id:) }

  describe 'creation' do
    context 'when there are duplicates' do
      it 'throws an ActiveRecord::RecordNotUnique error' do
        expect { cart.dup.save! }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    context 'with valid attributes' do
      it 'creates a new cart' do
        expect(cart).to be_valid
      end

      it 'has the correct data' do
        expect(cart.user_id).to_not be_nil
        expect(cart.developer_id).to_not be_nil
        expect(cart.app_id).to_not be_nil
      end

      context 'with invalid attributes: ActiveRecord::RecordInvalid' do
        it 'fails to create a new cart with no attributes' do
          expect { Cart.create! }.to raise_error(ActiveRecord::RecordInvalid)
        end

        it 'fails to create a new cart with no user_id' do
          expect do
            Cart.create!(developer_id:, app_id:)
          end.to raise_error(ActiveRecord::RecordInvalid)
        end

        it 'fails to create a new cart with no developer_id' do
          expect do
            Cart.create!(user_id:, app_id:)
          end.to raise_error(ActiveRecord::RecordInvalid)
        end

        it 'fails to create a new cart with no app_id' do
          expect do
            Cart.create!(user_id:, developer_id:)
          end.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end
  end

  describe 'updates' do
    context 'when updating the user ID' do
      it 'raises an ActiveRecord::ReadOnlyRecord error' do
        expect do
          cart.update!(user_id: SecureRandom.uuid)
        end.to raise_error(ActiveRecord::ReadOnlyRecord)
      end
    end

    context 'when updating the developer ID' do
      it 'raises an ActiveRecord::ReadOnlyRecord error' do
        expect do
          cart.update!(developer_id: SecureRandom.uuid)
        end.to raise_error(ActiveRecord::ReadOnlyRecord)
      end
    end

    context 'when updating the app ID' do
      it 'raises an ActiveRecord::ReadOnlyRecord error' do
        expect do
          cart.update!(app_id: SecureRandom.uuid)
        end.to raise_error(ActiveRecord::ReadOnlyRecord)
      end
    end

    context 'when updating the cart ID' do
      it 'raises an ActiveRecord::ReadOnlyRecord error' do
        expect do
          cart.update!(id: SecureRandom.uuid)
        end.to raise_error(ActiveRecord::ReadOnlyRecord)
      end
    end
  end

  describe 'deletion' do
    it 'deletes the cart' do
      cart.destroy
      expect(Cart.find_by(id: cart.id)).to be_nil
    end

    context 'when the cart is deleted' do
      let!(:cart_item) do
        FactoryBot.create(:cart_item, cart_id: cart.id)
      end

      it 'deletes the associated cart items' do
        cart.destroy

        expect(cart.destroyed?).to be(true)
        expect(CartItem.find_by(id: cart_item.id)).to be_nil
      end
    end

    context 'when the cart is not found or non-existent' do
      it 'raises an ActiveRecord::RecordNotFound error' do
        expect do
          Cart.find(SecureRandom.uuid)
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'associations' do
    context 'with cart items' do
      let!(:cart_item) do
        FactoryBot.create(:cart_item, cart_id: cart.id)
      end

      it 'has many cart items' do
        expect(cart.cart_items).to include(cart_item)
      end

      it 'deletes the associated cart items' do
        cart.destroy

        expect(CartItem.find_by(id: cart_item.id)).to be_nil
      end
    end
  end

  describe 'validations' do
    context 'when the user ID is not present' do
      it 'fails validation' do
        cart.user_id = nil
        expect(cart).to_not be_valid
      end
    end

    context 'when the developer ID is not present' do
      it 'fails validation' do
        cart.developer_id = nil
        expect(cart).to_not be_valid
      end
    end

    context 'when the app ID is not present' do
      it 'fails validation' do
        cart.app_id = nil
        expect(cart).to_not be_valid
      end
    end

    context 'when the user ID, developer ID, and app ID are present' do
      it 'passes validation' do
        expect(cart).to be_valid
      end
    end

    context 'when the user ID, developer ID, and app ID are not present' do
      it 'fails validation' do
        cart.user_id = nil
        cart.developer_id = nil
        cart.app_id = nil
        expect(cart).to_not be_valid
      end
    end

    context 'when the user ID is not unique' do
      it 'fails validation' do
        expect do
          FactoryBot.create(:cart, user_id: cart.user_id,
            developer_id: cart.developer_id,
            app_id: cart.app_id)
        end.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    context 'when a different developer creates a cart for the same user in ' \
      'the same app' do
      it 'fails validation' do
        expect do
          FactoryBot.create(
            :cart, user_id: cart.user_id,
            developer_id: SecureRandom.uuid,
            app_id: cart.app_id
          )
        end.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end

    context 'when a different developer creates a cart for the a different ' \
      'user in the same app' do
      it 'passes validation' do
        expect do
          FactoryBot.create(
            :cart, user_id: SecureRandom.uuid,
            developer_id: SecureRandom.uuid,
            app_id: cart.app_id
          )
        end.to_not raise_error
      end
    end
  end
end
