# frozen_string_literal: true

# Order model
class Order < ApplicationRecord
  has_many :order_items, dependent: :destroy

  enum :status, {
    pending: 'pending', successful: 'successful',
    failed: 'failed', cancelled: 'cancelled', processing: 'processing'
  }

  validates :status, comparison: { equal_to: 'pending' }, on: :create
  validates :status, inclusion: { in: statuses.keys }

  validates :total_amount,
            presence: true,
            numericality: { greater_than_or_equal_to: 0, only_numeric: true }

  validates :user_id, :app_id, :developer_id, :status, presence: true

  validate :no_pending_orders, on: :create

  scope :by_status, lambda { |status|
    where(status:) if status.present?
  }

  private

    def no_pending_orders
      return unless Order.exists?(user_id:, status: 'pending')

      errors.add(:base, 'You already have a pending order')
    end
end
