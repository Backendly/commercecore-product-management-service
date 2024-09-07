# frozen_string_literal: true

require 'rails_helper'
RSpec.describe Product, type: :model do
  let(:developer_id) { UUID7.generate }
  let(:user_id) { UUID7.generate }
  let(:category) do
    FactoryBot.create(:category, name: 'Home Appliances',
                                 description: 'Home appliance for user needs',
                                 developer_id:)
  end

  it 'throws an error when creating with a nil category_id' do
    expect do
      Product.create!(name: 'Laptop cases', developer_id:, category_id: nil,
                      price: 100, user_id:, stock_quantity: 10,
                      description: 'A case for laptops')
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
                          description: 'A case for laptops' * 3)

    expect(product).to be_valid

    product.save
    expect(Product.count).to eq(1)
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
end
