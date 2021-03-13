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

ActiveRecord::Schema.define(version: 2021_03_13_171910) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "candles", force: :cascade do |t|
    t.string "isin"
    t.string "ticker"
    t.string "interval", null: false
    t.datetime "time", null: false
    t.decimal "open", precision: 20, scale: 4, null: false
    t.decimal "close", precision: 20, scale: 4, null: false
    t.decimal "high", precision: 20, scale: 4, null: false
    t.decimal "low", precision: 20, scale: 4, null: false
    t.integer "volume", null: false
    t.string "source"
    t.datetime "created_at", default: -> { "CURRENT_DATE" }, null: false
    t.date "date"
    t.boolean "ongoing", default: false
    t.index ["isin", "interval", "date"], name: "index_candles_on_isin_and_interval_and_date", unique: true
    t.index ["isin", "interval", "time"], name: "index_candles_on_isin_and_interval_and_time", unique: true
    t.index ["isin"], name: "index_candles_on_isin"
    t.index ["ticker"], name: "index_candles_on_ticker"
  end

  create_table "instrument_infos", primary_key: "ticker", id: :string, force: :cascade do |t|
    t.string "name"
    t.string "industry"
    t.string "sector"
    t.string "country"
    t.bigint "marketcap"
    t.bigint "shares"
    t.float "beta"
    t.float "pe"
    t.float "dividend_yield"
    t.date "next_earnings_date"
    t.date "ex_divident_date"
    t.jsonb "company"
    t.datetime "company_updated_at"
    t.jsonb "stats"
    t.datetime "stats_updated_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "instruments", primary_key: "isin", id: :string, force: :cascade do |t|
    t.string "figi"
    t.string "ticker", null: false
    t.string "currency"
    t.string "name", null: false
    t.string "type", default: "Stock", null: false
    t.integer "lot"
    t.float "price_step"
    t.string "flags", default: [], array: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "has_logo"
    t.index ["figi"], name: "index_instruments_on_figi", unique: true
    t.index ["ticker"], name: "index_instruments_on_ticker"
  end

  create_table "prices", primary_key: "figi", id: :string, force: :cascade do |t|
    t.string "ticker", null: false
    t.decimal "value", precision: 20, scale: 4
    t.datetime "updated_at"
    t.index ["ticker"], name: "index_prices_on_ticker", unique: true
  end

  add_foreign_key "candles", "instruments", column: "isin", primary_key: "isin"
end
