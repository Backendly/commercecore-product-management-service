# frozen_string_literal: true

class AddProcessingToOrderStatus < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL
      ALTER TYPE order_status ADD VALUE 'processing';
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
