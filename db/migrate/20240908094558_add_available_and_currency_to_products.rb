# frozen_string_literal: true

class AddAvailableAndCurrencyToProducts < ActiveRecord::Migration[7.2]
  def change
    change_table :products, bulk: true do |t|
      t.boolean :available, default: true, null: false
      t.string :currency, default: 'USD', null: false
    end
  end
end
