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
end
