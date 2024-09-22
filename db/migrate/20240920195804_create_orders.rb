# frozen_string_literal: true

class CreateOrders < ActiveRecord::Migration[7.2]
  def up
    execute <<~SQL
            CREATE TYPE order_status AS ENUM (
            'pending', 'successful', 'failed', 'cancelled'
      );
    SQL

    create_table :orders, id: :uuid do |t|
      t.uuid :user_id, null: false
      t.uuid :developer_id, null: false
      t.uuid :app_id, null: false
      t.decimal :total_amount, precision: 10, scale: 2
      t.column :status, :order_status, null: false, default: 'pending'

      t.timestamps
    end
  end

  def down
    drop_table :orders

    execute <<-SQL
      DROP TYPE order_status;
    SQL
  end
end
