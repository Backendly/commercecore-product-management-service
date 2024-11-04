# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Product, type: :model do
  let(:developer_id) { UUID7.generate }
  let(:user_id) { UUID7.generate }
  let(:app_id) { UUID7.generate }
  let(:category) do
    FactoryBot.create(:category, name: 'Home Appliances',
                                 description: 'Home appliance for user needs',
                                 developer_id:)
  end

  it 'throws an error when creating with a nil category_id' do
    expect do
      Product.create!(
        name: 'Laptop cases', developer_id:, category_id: nil,
        price: 100, user_id:, stock_quantity: 10,
        description: 'A case for laptops',
        app_id: UUID7.generate
      )
    end.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'is invalid with a non-existent category_id' do
    product = Product.new(name: 'Laptop cases', developer_id:,
                          category_id: UUID7.generate, price: 100, user_id:,
                          stock_quantity: 10, description: 'A case for laptops')

    expect(product).to be_invalid
    expect(Product.count).to eq(0)
  end

  it 'is valid with all required attributes' do
    product = Product.new(name: 'Laptop cases', developer_id:,
                          category_id: category.id, price: 100, user_id:,
                          stock_quantity: 10,
                          description: 'A case for laptops' * 3,
                          app_id: UUID7.generate)

    expect(product).to be_valid

    product.save
    expect(Product.count).to eq(1)
  end

  context 'with a negative price' do
    let(:product) do
      FactoryBot.create(:product, price: 1)
    end

    it 'is invalid during updates' do
      product.update(price: -1)

      expect(product).not_to be_valid
      expect(product.errors.full_messages_for(:price)[0]).to eq(
        'Price must be greater than or equal to 0'
      )
    end

    it 'is invalid during creation' do
      product = Product.new(
        name: 'Laptop cases', developer_id:,
        category_id: category.id, price: -1, user_id:,
        stock_quantity: 10,
        description: Faker::Lorem.sentence(word_count: 15),
        app_id: UUID7.generate
      )

      expect(product).to be_invalid
      expect(product.errors.full_messages_for(:price)[0]).to eq(
        'Price must be greater than or equal to 0'
      )
    end
  end

  it 'is invalid without a name' do
    product = Product.new(developer_id:, category_id: category.id, price: 100,
                          user_id:, stock_quantity: 10,
                          description: 'A case for laptops' * 3)

    expect(product).not_to be_valid

    expect { product.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'is invalid with non-integer stock_quantity' do
    product = Product.new(name: 'Laptop cases', developer_id:,
                          category_id: category.id, price: 100, user_id:,
                          stock_quantity: 'ten',
                          description: 'A case for laptops')

    expect(product).not_to be_valid
    expect { product.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'is invalid with non-numeric price' do
    product = Product.new(name: 'Laptop cases', developer_id:,
                          category_id: category.id,
                          price: 'one hundred', user_id:,
                          stock_quantity: 10,
                          description: 'A case for laptops' * 3)

    expect(product).not_to be_valid
    expect { product.save! }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'is invalid with zero stock quantity during creation' do
    product = Product.new(name: 'Laptop cases', developer_id:,
                          category_id: category.id,
                          price: 13.56, user_id:,
                          stock_quantity: 0,
                          description: 'A case for laptops' * 3)

    expect(product).to be_invalid
    expect(product.errors.full_messages_for(:stock_quantity)[0]).to eq(
      'Stock quantity must be greater than or equal to 1'
    )
  end

  describe 'Duplicate product handling' do
    it 'rejects duplicate products for the same product owner' do
      expect do
        Product.create!(name: 'Laptop cases', developer_id:,
                        category_id: category.id, price: 100, user_id:,
                        stock_quantity: 10,
                        description: 'A case for laptops' * 3, app_id:)
      end.to_not raise_error

      product = Product.first
      expect(product.name).to eq('Laptop cases')
      expect(Product.count).to eq(1)

      expect do
        Product.create!(name: 'Laptop cases', developer_id:,
                        category_id: category.id, price: 100, user_id:,
                        stock_quantity: 10,
                        description: 'A case for laptops' * 3, app_id:)
      end.to raise_error(ActiveRecord::RecordNotUnique)

      expect(Product.count).to eq(1)
    end

    it 'allows similar product names for different users' do
      second_user_id = UUID7.generate

      # first product
      expect do
        Product.create!(name: 'Laptop cases', developer_id:,
                        category_id: category.id,
                        price: 100, user_id:, stock_quantity: 10,
                        description: 'A case for laptops' * 3,
                        app_id:)
      end.to_not raise_error
      expect(Product.count).to eq(1)

      # second product
      expect do
        Product.create!(name: 'Laptop cases', developer_id:,
                        category_id: category.id,
                        price: 100, user_id: second_user_id,
                        stock_quantity: 10,
                        description: 'A case for laptops' * 3, app_id:)
      end.to_not raise_error

      expect(Product.count).to eq(2)

      expect(Product.first.user_id).to eq(user_id)
      expect(Product.last.user_id).to eq(second_user_id)

      expect(category.products).to eq([ Product.first, Product.last ])
    end
  end

  describe 'Deletions' do
    # create a home appliance product
    let!(:product) do
      Product.create!(name: 'Washing Machine', developer_id:,
                      category_id: category.id,
                      price: 100, user_id:,
                      stock_quantity: 10,
                      description: 'A washing machine for user needs' * 4,
                      app_id:)
    end

    it 'allows deletion of a product' do
      expect { product.destroy }.to change(Product, :count).by(-1)
    end

    it 'removes the product from the category' do
      expect { product.destroy }.to change { category.products.count }.by(-1)
    end

    it 'does not allow deletion of a product by a different user' do
      different_user = UUID7.generate
      expect do
        Product.destroy_by(user_id: different_user, developer_id:)
      end.not_to change(Product, :count)
    end

    it 'allows deletion of a product by the same user' do
      expect do
        Product.destroy_by(user_id:, developer_id:)
      end.to change(Product, :count).by(-1)
    end
  end

  describe 'Updating a product' do
    let(:product) do
      Product.create!(
        name: 'Laptop cases', developer_id:,
        category_id: category.id,
        price: 100, user_id:, stock_quantity: 10,
        description: 'A case for laptops' * 3,
        app_id:
      )
    end

    it 'updates the name successfully' do
      expect do
        product.update(name: 'Updated Laptop cases')
      end.to change { product.name }
        .from('Laptop cases').to('Updated Laptop cases')
    end

    it 'fails to update with an invalid name' do
      expect do
        product.update!(name: '')
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(product.reload.name).to eq('Laptop cases')
    end

    it 'updates the price successfully' do
      expect do
        product.update(price: 150)
      end.to change { product.price }.from(100).to(150)
    end

    it 'fails to update with a non-numeric price' do
      expect do
        product.update!(price: 'one hundred fifty')
      end.to raise_error(ActiveRecord::RecordInvalid)
      expect(product.reload.price).to eq(100)
    end

    it 'updates the stock quantity successfully' do
      expect do
        product.update(stock_quantity: 20)
      end.to change { product.stock_quantity }.from(10).to(20)
    end

    it 'fails to update with a non-integer stock quantity' do
      expect do
        product.update!(stock_quantity: 'twenty')
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(product.reload.stock_quantity).to eq(10)
    end

    it 'updates the description successfully' do
      product.update(
        description: 'Updated description for laptops and it is also ten words'
      )
      expect(product.reload.description).to eq(
        'Updated description for laptops and it is also ten words'
      )
    end

    it 'fails to update with a short description' do
      expect do
        product.update!(description: 'Short')
      end.to raise_error(ActiveRecord::RecordInvalid)
      expect(product.reload.description).to eq('A case for laptops' * 3)
    end

    it 'updates the available status successfully' do
      expect do
        product.update(available: false)
      end.to change { product.available }.from(true).to(false)
    end

    it 'updates the currency successfully' do
      product.update(currency: 'EUR')
      expect(product.reload.currency).to eq('EUR')
    end

    it 'fails to update with an invalid currency' do
      expect do
        product.update!(currency: '')
      end.to raise_error(ActiveRecord::RecordInvalid)
      expect(product.reload.currency).to eq('USD')
    end
  end
end
