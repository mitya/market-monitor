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

ActiveRecord::Schema.define(version: 2021_03_30_134627) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "aggregates", force: :cascade do |t|
    t.string "ticker", null: false
    t.date "date", null: false
    t.boolean "current", default: false, null: false
    t.float "d1"
    t.float "d1_vol"
    t.float "d2"
    t.float "d2_vol"
    t.float "d3"
    t.float "d3_vol"
    t.float "d4"
    t.float "d4_vol"
    t.float "w1"
    t.float "w1_vol"
    t.float "w2"
    t.float "w2_vol"
    t.float "m1"
    t.float "m1_vol"
    t.float "y2021"
    t.float "nov06"
    t.float "mar23"
    t.float "feb19"
    t.float "y2020"
    t.float "y2019"
    t.jsonb "data", default: {}
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["ticker", "date"], name: "index_aggregates_on_ticker_and_date", unique: true
    t.index ["ticker"], name: "index_aggregates_on_ticker"
  end

  create_table "candles", force: :cascade do |t|
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
    t.datetime "updated_at"
    t.index ["ticker", "interval", "date"], name: "index_candles_on_ticker_interval_date"
    t.index ["ticker"], name: "index_candles_on_ticker"
  end

  create_table "insider_transactions", force: :cascade do |t|
    t.string "ticker"
    t.string "insider_name"
    t.string "insider_title"
    t.date "date"
    t.date "filling_date"
    t.string "kind"
    t.integer "shares"
    t.integer "shares_final"
    t.decimal "price", precision: 20, scale: 4
    t.decimal "cost", precision: 20, scale: 4
    t.string "sec_code"
    t.string "source"
    t.jsonb "data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["date"], name: "index_insider_transactions_on_date"
    t.index ["ticker"], name: "index_insider_transactions_on_ticker"
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
    t.string "sector_code"
    t.jsonb "advanced_stats"
    t.datetime "advanced_stats_updated_at"
  end

  create_table "instruments", primary_key: "ticker", id: :string, force: :cascade do |t|
    t.string "isin"
    t.string "figi"
    t.string "currency"
    t.string "name", null: false
    t.string "type", default: "Stock", null: false
    t.integer "lot"
    t.float "price_step"
    t.string "flags", default: [], array: true
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.boolean "has_logo"
    t.string "exchange"
    t.index ["figi"], name: "index_instruments_on_figi", unique: true
    t.index ["isin"], name: "index_instruments_on_isin", unique: true
  end

  create_table "portfolio_items", primary_key: "ticker", id: :string, force: :cascade do |t|
    t.integer "lots"
    t.string "lots_expr"
    t.decimal "price", precision: 20, scale: 4
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "price_targets", force: :cascade do |t|
    t.string "ticker", null: false
    t.date "date"
    t.decimal "high", precision: 20, scale: 4
    t.decimal "low", precision: 20, scale: 4
    t.decimal "average", precision: 20, scale: 4
    t.string "currency"
    t.integer "analysts_count"
    t.string "source"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["ticker", "date"], name: "index_price_targets_on_ticker_and_date", unique: true
  end

  create_table "prices", primary_key: "ticker", id: :string, force: :cascade do |t|
    t.decimal "value", precision: 20, scale: 4
    t.datetime "updated_at"
    t.datetime "last_at"
    t.string "source"
    t.index ["ticker"], name: "index_prices_on_ticker", unique: true
  end

  create_table "recommendations", force: :cascade do |t|
    t.string "ticker", null: false
    t.integer "buy"
    t.integer "overweight"
    t.integer "hold"
    t.integer "underweight"
    t.integer "sell"
    t.integer "none"
    t.float "scale"
    t.float "scale15"
    t.boolean "current"
    t.date "corporate_action_date"
    t.date "starts_on"
    t.date "ends_on"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["current"], name: "index_recommendations_on_current"
    t.index ["ticker"], name: "index_recommendations_on_ticker"
  end

end
