# frozen_string_literal: true

class CreateProducts < ActiveRecord::Migration[7.2]
  def change
    create_table :products, id: :uuid do |t|
      t.string :name
      t.text :description
      t.decimal :price
      t.integer :stock_quantity
      t.references :category, null: false, foreign_key: true, type: :uuid
      t.uuid :user_id
      t.uuid :developer_id

      t.timestamps
    end
  end
end
