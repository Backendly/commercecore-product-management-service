# frozen_string_literal: true

class AddUniqueIndexToCartForUsers < ActiveRecord::Migration[7.2]
  def change
    add_index :carts, %i[app_id developer_id user_id], unique: true
  end
end
