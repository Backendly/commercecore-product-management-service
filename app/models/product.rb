# frozen_string_literal: true

# Product model
class Product < ApplicationRecord
  include WordCountValidatable

  belongs_to :category, optional: true

  validates :developer_id, :name, :price, :user_id, :app_id,
            :stock_quantity, :description, :currency, presence: true
  validates :available, inclusion: { in: [true, false] }

  validate :price_must_be_numeric
  validates :stock_quantity, numericality: { only_integer: true }
  validates :price, numericality: { only_numeric: true }

  # ensure there's at least one product before it is created
  validates :stock_quantity,
            numericality: { greater_than_or_equal_to: 1 }, on: :create

  validates_word_count_of :name, min_words: 1, max_words: 20
  validates_word_count_of :description, min_words: 10, max_words: 100

  validates :name, length: { minimum: 3 }

  private

    def price_must_be_numeric
      errors.add(:price, 'must be a number') unless price.is_a?(Numeric)
    end
end
