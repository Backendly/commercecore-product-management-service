# frozen_string_literal: true

# Category model
class Category < ApplicationRecord
  include WordCountValidatable

  has_many :products, dependent: :nullify

  validates :name, :description,
            presence: { message: '%<value>s must be provided' },
            length: { minimum: 3 }

  validates :developer_id,
            presence: { message: 'developer_id must be provided' }

  validates_word_count_of :description, min_words: 2, max_words: 10
  validates_word_count_of :name, min_words: 1, max_words: 10

  scope :by_developer, ->(developer_id) { where(developer_id:) }
  scope :by_name, lambda { |name|
    where('name ILIKE ?', "%#{name}%") if name.present?
  }
  scope :by_search, lambda { |search|
    if search.present?
      where(
        'name ILIKE :search OR description ILIKE :search',
        search: "%#{search}%"
      )
    end
  }
end
