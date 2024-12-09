# frozen_string_literal: true

# Product model
class Product < ApplicationRecord
  include WordCountValidatable

  scope :by_name, lambda { |name|
    if name.present?
      where("name ILIKE ?", "%" + Product.sanitize_sql_like(name) + "%")
    end
  }
  scope :by_category, lambda { |category_id|
    where(category_id:) if category_id.present?
  }
  scope :by_price_range, lambda { |min_price, max_price|
    if min_price.present? && max_price.present?
      where(price: min_price..max_price)
    end
  }

  belongs_to :category, optional: true
  has_many_attached :images

  validates :images,
            content_type: {
              in: %w[image/png image/jpg image/jpeg images/webp]
            }
  validates :images,
            size: {
              max_size: 2.megabytes,
              message: "size must be less than 2MB"
            }

  validates :developer_id, :name, :price, :user_id, :app_id,
            :stock_quantity, :description, :currency, presence: true
  validates :available, inclusion: { in: [ true, false ] }

  validate :price_must_be_numeric
  validates :stock_quantity, numericality: { only_integer: true }
  validates :price,
            numericality: { only_numeric: true, greater_than_or_equal_to: 0 }

  # ensure there's at least one product before it is created
  validates :stock_quantity,
            numericality: { greater_than_or_equal_to: 1 }, on: :create

  validates_word_count_of :name, min_words: 1, max_words: 20
  validates_word_count_of :description, min_words: 10, max_words: 100

  validates :name, length: { minimum: 3 }

  private

    def price_must_be_numeric
      errors.add(:price, "must be a number") unless price.is_a?(Numeric)
    end
end
