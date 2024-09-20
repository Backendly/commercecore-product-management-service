# frozen_string_literal: true

class CreateCarts < ActiveRecord::Migration[7.2]
  def change
    create_table :carts, id: :uuid do |t|
      t.uuid :user_id
      t.uuid :developer_id
      t.uuid :app_id

      t.timestamps
    end
  end
end
