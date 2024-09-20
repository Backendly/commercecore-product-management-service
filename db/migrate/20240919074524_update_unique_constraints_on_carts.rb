# frozen_string_literal: true

class UpdateUniqueConstraintsOnCarts < ActiveRecord::Migration[7.2]
  def change
    remove_index :carts, %i[user_id developer_id app_id] if index_exists?(
      :carts, %i[user_id developer_id app_id]
    )
  end

  add_index :carts, %i[user_id app_id], unique: true
end
