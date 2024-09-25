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

ActiveRecord::Schema[7.2].define(version: 20_240_925_094_612) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "order_status",
              %w[pending successful failed cancelled processing refunded]

  create_table "active_storage_attachments", id: :uuid, default: lambda {
    "gen_random_uuid()"
  }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index %w[record_type record_id name blob_id],
            name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: lambda {
    "gen_random_uuid()"
  }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: lambda {
    "gen_random_uuid()"
  }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index %w[blob_id variation_digest],
            name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "cart_items", id: :uuid, default: lambda {
    "gen_random_uuid()"
  }, force: :cascade do |t|
    t.uuid "cart_id", null: false
    t.uuid "product_id", null: false
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["product_id"], name: "index_cart_items_on_product_id"
  end

  create_table "carts", id: :uuid, default: lambda {
    "gen_random_uuid()"
  }, force: :cascade do |t|
    t.uuid "user_id"
    t.uuid "developer_id"
    t.uuid "app_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index %w[app_id developer_id user_id],
            name: "index_carts_on_app_id_and_developer_id_and_user_id", unique: true
    t.index %w[user_id app_id], name: "index_carts_on_user_id_and_app_id",
                                unique: true
  end

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

  create_table "order_items", id: :uuid, default: lambda {
    "gen_random_uuid()"
  }, force: :cascade do |t|
    t.uuid "order_id", null: false
    t.uuid "product_id", null: false
    t.integer "quantity", null: false
    t.decimal "price_at_purchase", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", id: :uuid, default: lambda {
    "gen_random_uuid()"
  }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "developer_id", null: false
    t.uuid "app_id", null: false
    t.decimal "total_amount", precision: 10, scale: 2
    t.enum "status", default: "pending", null: false, enum_type: "order_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "products", id: :uuid, default: lambda {
    "gen_random_uuid()"
  }, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "price"
    t.integer "stock_quantity"
    t.uuid "category_id"
    t.uuid "user_id"
    t.uuid "developer_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "available", default: true, null: false
    t.string "currency", default: "USD", null: false
    t.uuid "app_id"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index %w[name developer_id user_id],
            name: "index_products_on_name_and_developer_id_and_user_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs",
                  column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs",
                  column: "blob_id"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "products", "categories"
end
