# frozen_string_literal: true

class CreateCategories < ActiveRecord::Migration[7.2]
  def change
    create_table :categories, id: :uuid do |t|
      t.string :name
      t.text :description
      t.uuid :developer_id

      t.timestamps
    end
  end
end
