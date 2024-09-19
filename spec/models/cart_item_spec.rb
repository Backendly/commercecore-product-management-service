# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CartItem, type: :model do
  let!(:cart) { FactoryBot.create(:cart) }
  let!(:products) { FactoryBot.create_list(:product, 5) }

  let!(:cart_item) do
    FactoryBot.create(:cart_item, cart:, product: products.first)
  end

  describe 'creation' do
    context 'with valid attributes' do
      it 'creates a new cart item' do
        expect(cart_item).to be_valid
      end
    end

    context 'with invalid attributes' do
      it 'fails to create a new cart item with no attributes' do
        expect { CartItem.create! }.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'fails to create a new cart item with no cart' do
        expect do
          CartItem.create!(product: products.first, quantity: 1)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'fails to create a new cart with a non-existing cart' do
        expect do
          CartItem.create!(
            cart_id: SecureRandom.uuid,
            product: products.first, quantity: 1
          )
        end.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'fails to create a new cart item with no product' do
        expect do
          CartItem.create!(cart_id: cart.id, quantity: 1)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end

      it 'fails to create a new cart item with no quantity' do
        expect do
          CartItem.create!(cart_id: cart.id, product: products.first)
        end.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe 'associations' do
    it 'belongs to a cart' do
      expect(cart_item.cart).to eq(cart)
    end

    it 'belongs to a product' do
      expect(cart_item.product).to eq(products.first)
    end
  end

  describe 'validations' do
    it 'validates the presence of cart_id' do
      cart_item.cart_id = nil
      expect(cart_item).to_not be_valid
    end

    it 'validates the presence of product_id' do
      cart_item.product_id = nil
      expect(cart_item).to_not be_valid
    end

    it 'validates the presence of quantity' do
      cart_item.quantity = nil
      expect(cart_item).to_not be_valid
    end

    it 'validates that the quantity is not negative' do
      cart_item.quantity = -1
      expect(cart_item).to_not be_valid
    end

    it 'validates that the quantity is not zero' do
      cart_item.quantity = 0
      expect(cart_item).to_not be_valid
    end
  end

  describe 'destruction' do
    it 'destroys the cart item when the cart is destroyed' do
      cart.destroy

      expect(CartItem.find_by(id: cart_item.id)).to be_nil
    end
  end

  describe 'updating' do
    it 'updates the quantity of the cart item' do
      cart_item.update!(quantity: 2)

      expect(cart_item.reload.quantity).to eq(2)
    end

    it 'updates the product of the cart item' do
      cart_item.update!(product: products.second)

      expect(cart_item.reload.product).to eq(products.second)
    end

    it 'forbids changing the cart' do
      expect do
        cart_item.update!(cart: FactoryBot.create(:cart))
      end.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end

    it 'does not allow the cart_id to be changed after creation' do
      expect do
        cart_item.update!(cart: FactoryBot.create(:cart))
      end.to raise_error(ActiveRecord::ReadonlyAttributeError,
        /cannot be changed once set/)
    end
  end

  describe 'deletion' do
    it 'deletes the cart item' do
      cart_item.destroy
      expect(CartItem.find_by(id: cart_item.id)).to be_nil
    end

    context 'when the cart item is deleted' do
      it 'deletes the cart item' do
        cart_item.destroy
        expect(CartItem.find_by(id: cart_item.id)).to be_nil
      end
    end

    context 'when the cart is deleted' do
      it 'deletes the associated cart items' do
        cart.destroy

        expect(cart.destroyed?).to be(true)
        expect(CartItem.find_by(id: cart_item.id)).to be_nil
      end
    end
  end

  describe 'searching' do
    it 'finds the cart item by cart' do
      expect(CartItem.find_by(cart:)).to eq(cart_item)
    end

    it 'finds the cart item by product' do
      expect(CartItem.find_by(product: products.first)).to eq(cart_item)
    end

    it 'finds the cart item by quantity' do
      expect(CartItem.find_by(quantity: cart_item.quantity)).to eq(cart_item)
    end
  end

  describe 'listing' do
    it 'lists all cart items' do
      expect(CartItem.all).to include(cart_item)
    end

    it 'lists all cart items by cart' do
      expect(CartItem.where(cart:)).to include(cart_item)
    end

    it 'lists all cart items by product' do
      expect(CartItem.where(product: products.first)).to include(cart_item)
    end

    it 'lists all cart items by quantity' do
      expect(CartItem.where(quantity: cart_item.quantity)).to include(cart_item)
    end

    it 'lists all cart items by cart and product' do
      expect(
        CartItem.where(cart:, product: products.first)
      ).to include(cart_item)
    end
  end
end
