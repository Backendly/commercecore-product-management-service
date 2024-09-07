# frozen_string_literal: true

class AddUniqueIndexToCategoriesName < ActiveRecord::Migration[7.2]
  def change
    add_index :categories, %i[name developer_id], unique: true
  end
end
