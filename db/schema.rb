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

ActiveRecord::Schema[8.0].define(version: 2025_08_24_070839) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.string "address_detail_pid", null: false
    t.string "street_locality_pid"
    t.integer "locality_id", null: false
    t.integer "street_type_id"
    t.integer "number_first"
    t.string "number_suffix", limit: 15
    t.integer "number_last"
    t.string "number_last_suffix", limit: 15
    t.string "street_name", null: false
    t.string "street_class_code"
    t.string "street_class_type"
    t.string "level_type_code"
    t.string "level_type"
    t.string "level_number_prefix"
    t.integer "level_number"
    t.string "level_number_suffix"
    t.string "flat_type_code"
    t.string "flat_type"
    t.string "flat_number_prefix"
    t.integer "flat_number"
    t.string "flat_number_suffix"
    t.string "building_name"
    t.string "lot_number_prefix"
    t.string "lot_number"
    t.string "lot_number_suffix"
    t.decimal "latitude", precision: 10, scale: 8
    t.decimal "longitude", precision: 11, scale: 8
    t.integer "geocode_reliability_code"
    t.string "confidence"
    t.string "legal_parcel_id"
    t.date "date_created"
    t.date "date_last_modified"
    t.date "date_retired"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "postcode"
    t.index ["address_detail_pid"], name: "index_addresses_on_address_detail_pid", unique: true
    t.index ["building_name"], name: "index_addresses_on_building_name"
    t.index ["latitude", "longitude"], name: "index_addresses_on_latitude_and_longitude"
    t.index ["locality_id"], name: "index_addresses_on_locality_id"
    t.index ["number_first"], name: "index_addresses_on_number_first"
    t.index ["postcode"], name: "index_addresses_on_postcode"
    t.index ["street_name"], name: "index_addresses_on_street_name"
    t.index ["street_type_id"], name: "index_addresses_on_street_type_id"
  end

  create_table "localities", force: :cascade do |t|
    t.string "locality_pid", null: false
    t.string "locality_name", null: false
    t.string "locality_class_code"
    t.string "locality_class_name"
    t.integer "state_id", null: false
    t.string "postcode"
    t.decimal "latitude", precision: 10, scale: 8
    t.decimal "longitude", precision: 11, scale: 8
    t.date "date_created"
    t.date "date_retired"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["latitude", "longitude"], name: "index_localities_on_latitude_and_longitude"
    t.index ["locality_name"], name: "index_localities_on_locality_name"
    t.index ["locality_pid"], name: "index_localities_on_locality_pid", unique: true
    t.index ["postcode"], name: "index_localities_on_postcode"
    t.index ["state_id"], name: "index_localities_on_state_id"
  end

  create_table "states", force: :cascade do |t|
    t.string "state_pid", null: false
    t.string "state_name", null: false
    t.string "state_abbreviation", limit: 3, null: false
    t.date "date_created"
    t.date "date_retired"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["state_abbreviation"], name: "index_states_on_state_abbreviation"
    t.index ["state_pid"], name: "index_states_on_state_pid", unique: true
  end

  create_table "street_types", force: :cascade do |t|
    t.string "street_type_code", null: false
    t.string "street_type_name", null: false
    t.string "street_type_description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["street_type_code"], name: "index_street_types_on_street_type_code", unique: true
  end

  add_foreign_key "addresses", "localities"
  add_foreign_key "addresses", "street_types"
  add_foreign_key "localities", "states"
end
