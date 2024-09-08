# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Category, type: :model do
  describe 'Developer ID validations' do
    it 'throws an error when the developer_id is omitted' do
      expect do
        Category.create!(name: 'Electronics',
                         description: 'Everything electronics')
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'throws an error when the developer_id is not a UUID' do
      expect do
        Category.create!(name: 'Category 1', description: 'A short Description',
                         developer_id: 1234)
      end.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'creates the category when the developer_id is present and valid' do
      developer_id = UUID7.generate

      expect do
        Category.create(name: 'Category 1',
                        description: 'Description for category 1',
                        developer_id:)
      end.to_not raise_error

      expect(Category.count).to eq(1)
      category = Category.first

      expect(category.name).to eq('Category 1')
      expect(category.developer_id).to eq(developer_id)
    end
  end

  describe 'Description field length constraints' do
    it 'rejects categories with no descriptions' do
      expect do
        Category.create!(name: 'Category 1', developer_id: UUID7.generate)
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(Product.count).to eq(0)
    end

    it 'rejects categories with a description of less than 2 words' do
      expect do
        Category.create!(name: 'Category 1', developer_id: UUID7.generate,
                         description: 'Category')
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(Product.count).to eq(0)
    end

    it 'handles only whitespace characters-only description' do
      expect do
        Category.create!(name: 'White-spaced Description Category',
                         developer_id: UUID7.generate, description: ' ' * 2)
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(Product.count).to eq(0)
    end

    it 'creates a category with a description of at least two words' do
      expect do
        Category.create!(name: 'Home Appliances',
                         developer_id: UUID7.generate,
                         description: 'Everything Appliances')
      end.to_not raise_error

      expect(Category.count).to eq(1)
    end

    it 'creates a category with a description of at most ten words' do
      description = 'For all products in the home appliance and ' \
        'electronics family'
      expect do
        Category.create!(name: 'Home Appliances',
                         developer_id: UUID7.generate, description:)
      end.to_not raise_error

      expect(Category.count).to eq(1)
    end

    it 'rejects categories with more than ten words for description' do
      description = 'description ' * 11

      appliance = Category.create(name: 'Home Appliances',
                                  developer_id: UUID7.generate, description:)

      expect(Category.count).to eq(0)
      expect(appliance).to be_invalid

      expect(appliance.errors.full_messages[0]).to eq(
        'Description must be between 2 and 10 words'
      )
    end

    it 'throws an error on duplicate category creation' do
      developer_id = UUID7.generate

      # first time
      Category.create!(name: 'Home Appliances',
                       developer_id:,
                       description: 'Home appliance products category')

      # second time
      expect do
        Category.create!(name: 'Home Appliances',
                         developer_id:,
                         description: 'Home appliance products category')
      end.to raise_error(ActiveRecord::RecordNotUnique)

      expect(Category.count).to eq(1)
    end

    it 'creates the same category for two different developers' do
      developer_1_id = UUID7.generate
      developer_2_id = UUID7.generate

      # first time
      Category.create!(name: 'Home Appliances',
                       developer_id: developer_1_id,
                       description: 'Home appliance products category')

      # second time
      expect do
        Category.create!(name: 'Home Appliances',
                         developer_id: developer_2_id,
                         description: 'Home appliance products category')
      end.to_not raise_error

      expect(Category.count).to eq(2)
    end
  end

  describe 'Update category' do
    let!(:developer_id) { UUID7.generate }

    let!(:home_appliance) do
      Category.create!(name: 'Home Appliances',
                       description: 'Home appliance products category',
                       developer_id:)
    end

    let!(:computer_accessories) do
      Category.create!(
        name: 'Computer Accessories',
        description: 'Category for everything peripherals to a computer',
        developer_id:
      )
    end

    it 'allows for updates when the correct data is provided' do
      home_appliance.update!(name: 'Updated Home appliance')
      expect(home_appliance.reload.name).to eq('Updated Home appliance')
    end

    it 'rejects when the name of the category is not set' do
      expect do
        home_appliance.update!(name: nil)
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(home_appliance.reload.name).to eq('Home Appliances')
    end

    it 'rejects updates when the new name maps to an existing record' do
      expect do
        computer_accessories.update!(name: 'Home Appliances')
      end.to raise_error(ActiveRecord::RecordNotUnique)

      expect(computer_accessories.reload.name).to eq('Computer Accessories')
    end
  end

  describe 'Delete category' do
    let!(:developer_id) { UUID7.generate }

    let!(:home_appliance) do
      Category.create!(name: 'Home Appliances',
                       description: 'Home appliance products category',
                       developer_id:)
    end

    it 'deletes the category when provided the right ID' do
      expect(Category.count).to eq(1)

      Category.destroy(home_appliance.id)

      expect(Category.count).to eq(0)
    end

    it 'can delete on the instance' do
      expect(Category.count).to eq(1)

      home_appliance.destroy

      expect(Category.count).to eq(0)
    end

    it 'nullifies category_id field on dependent products' do
      expect do
        Product.create!(
          name: 'Binatone 3 in 1 Blender', developer_id:,
          category_id: home_appliance.id, price: 100, user_id: UUID7.generate,
          stock_quantity: 10,
          description: 'This is an amazing blender for all your ' \
            'cooking needs in household.'
        )
      end.to_not raise_error

      product = Product.first

      # save the home appliance for later verifications
      category_id = home_appliance.id

      expect(product.category_id).to eq(home_appliance.id)

      home_appliance.destroy!

      expect(home_appliance.destroyed?).to eq(true)

      expect do
        Category.find(category_id)
      end.to raise_error(ActiveRecord::RecordNotFound)

      # ensure the category_id was nullified after the category is deleted
      expect(product.reload.category_id).to eq(nil)
    end

    it 'fails when an invalid ID is provided' do
      expect do
        Category.destroy(UUID7.generate)
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  # let's work on testing the updates
  describe 'Update category' do
    let!(:developer_id) { UUID7.generate }

    let!(:home_appliance) do
      Category.create!(name: 'Home Appliances',
                       description: 'Home appliance products category',
                       developer_id:)
    end

    let!(:computer_accessories) do
      Category.create!(
        name: 'Computer Accessories',
        description: 'Category for everything peripherals to a computer',
        developer_id:
      )
    end

    it 'allows for updates when the correct data is provided' do
      home_appliance.update!(name: 'Updated Home appliance')
      expect(home_appliance.reload.name).to eq('Updated Home appliance')
      expect do
        home_appliance.update(name: 'Updated Home appliance').to change
      end
    end

    it 'changes the updated_at field on update' do
      expect do
        home_appliance.update(name: 'Updated Home appliance')
      end.to(change { home_appliance.updated_at })
    end

    it 'rejects when the name of the category is not set' do
      expect do
        home_appliance.update!(name: nil)
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(home_appliance.reload.name).to eq('Home Appliances')
    end

    it 'rejects updates when the new name maps to an existing record' do
      expect do
        computer_accessories.update!(name: 'Home Appliances')
      end.to raise_error(ActiveRecord::RecordNotUnique)

      expect(computer_accessories.reload.name).to eq('Computer Accessories')
    end
  end
end
