# frozen_string_literal: true

class AddUniqueIndexToProductsName < ActiveRecord::Migration[7.2]
  def change
    add_index :products, %i[name developer_id user_id], unique: true
  end
end
