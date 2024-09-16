# frozen_string_literal: true

class AddAppIdFieldToProducts < ActiveRecord::Migration[7.2]
  def change
    add_column :products, :app_id, :uuid
  end
end
