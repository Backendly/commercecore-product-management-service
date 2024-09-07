# frozen_string_literal: true

# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 20_240_907_131_847) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "categories", id: :uuid, default: lambda {
    "gen_random_uuid()"
  }, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.uuid "developer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index %w[name developer_id],
            name: "index_categories_on_name_and_developer_id", unique: true
  end

  create_table "products", id: :uuid, default: lambda {
    "gen_random_uuid()"
  }, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "price"
    t.integer "stock_quantity"
    t.uuid "category_id", null: false
    t.uuid "user_id"
    t.uuid "developer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index %w[name developer_id user_id],
            name: "index_products_on_name_and_developer_id_and_user_id", unique: true
  end

  add_foreign_key "products", "categories"
end
