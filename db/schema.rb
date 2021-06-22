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

ActiveRecord::Schema.define(version: 2021_06_22_124754) do

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
    t.integer "days_up"
    t.jsonb "data", default: {}
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.date "lowest_day_date"
    t.float "lowest_day_gain"
    t.float "y2018"
    t.float "y2017"
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
    t.boolean "analyzed"
    t.index ["ticker", "interval", "date"], name: "index_candles_on_ticker_interval_date"
    t.index ["ticker", "interval", "date"], name: "uniq_ticker_date_for_days", where: "((\"interval\")::text = 'day'::text)"
    t.index ["ticker"], name: "index_candles_on_ticker"
  end

  create_table "candles_h1", force: :cascade do |t|
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
    t.boolean "analyzed"
    t.index ["ticker", "interval", "date"], name: "candles_1h_ticker_interval_date_idx"
    t.index ["ticker", "interval", "date"], name: "candles_1h_ticker_interval_date_idx1", where: "((\"interval\")::text = 'day'::text)"
    t.index ["ticker"], name: "candles_1h_ticker_idx"
  end

  create_table "candles_m1", force: :cascade do |t|
    t.string "ticker", null: false
    t.string "interval", default: "1min", null: false
    t.date "date", null: false
    t.time "time", null: false
    t.decimal "open", precision: 20, scale: 4, null: false
    t.decimal "close", precision: 20, scale: 4, null: false
    t.decimal "high", precision: 20, scale: 4, null: false
    t.decimal "low", precision: 20, scale: 4, null: false
    t.integer "volume", null: false
    t.string "source", default: "iex", null: false
    t.boolean "ongoing", default: false, null: false
    t.boolean "analyzed", default: false, null: false
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.datetime "updated_at", default: -> { "now()" }, null: false
    t.index ["ticker", "date"], name: "candles_m1_ticker_interval_date_idx"
    t.index ["ticker"], name: "candles_m1_ticker_idx"
  end

  create_table "candles_m5", force: :cascade do |t|
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
    t.boolean "analyzed"
    t.index ["ticker", "interval", "date"], name: "candles_5m_ticker_interval_date_idx"
    t.index ["ticker", "interval", "date"], name: "candles_5m_ticker_interval_date_idx1", where: "((\"interval\")::text = 'day'::text)"
    t.index ["ticker"], name: "candles_5m_ticker_idx"
  end

  create_table "insider_aggregates", force: :cascade do |t|
    t.string "ticker", null: false
    t.bigint "m1_buys_total"
    t.decimal "m1_buys_avg", precision: 20, scale: 4
    t.bigint "m1_sells_total"
    t.decimal "m1_sells_avg", precision: 20, scale: 4
    t.bigint "m2_buys_total"
    t.decimal "m2_buys_avg", precision: 20, scale: 4
    t.bigint "m2_sells_total"
    t.decimal "m2_sells_avg", precision: 20, scale: 4
    t.bigint "m3_buys_total"
    t.decimal "m3_buys_avg", precision: 20, scale: 4
    t.bigint "m3_sells_total"
    t.decimal "m3_sells_avg", precision: 20, scale: 4
    t.bigint "m6_buys_total"
    t.decimal "m6_buys_avg", precision: 20, scale: 4
    t.bigint "m6_sells_total"
    t.decimal "m6_sells_avg", precision: 20, scale: 4
    t.string "sa_1_score"
    t.string "sa_1_price"
    t.string "sa_2_score"
    t.string "sa_2_price"
    t.string "sa_3_score"
    t.string "sa_3_price"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "insider_summaries", force: :cascade do |t|
    t.string "ticker", null: false
    t.string "name"
    t.string "title"
    t.bigint "net"
    t.bigint "bought"
    t.bigint "sold"
    t.date "date"
    t.string "source"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
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

  create_table "institution_holdings", force: :cascade do |t|
    t.string "ticker", null: false
    t.string "holder", null: false
    t.bigint "shares"
    t.bigint "shares_na"
    t.bigint "value"
    t.date "date"
    t.date "reported_on"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["holder"], name: "index_institution_holdings_on_holder"
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
    t.text "iex_ticker"
    t.date "first_date"
    t.index ["figi"], name: "index_instruments_on_figi", unique: true
    t.index ["isin"], name: "index_instruments_on_isin", unique: true
  end

  create_table "portfolio_items", primary_key: "ticker", id: :string, force: :cascade do |t|
    t.decimal "price", precision: 20, scale: 4
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "tinkoff_lots"
    t.integer "tinkoff_iis_lots"
    t.integer "vtb_lots"
    t.integer "ideal_lots"
    t.boolean "active", default: true
  end

  create_table "price_level_hits", force: :cascade do |t|
    t.string "ticker", null: false
    t.bigint "level_id", null: false
    t.decimal "level_value", precision: 20, scale: 4
    t.string "kind"
    t.boolean "exact"
    t.boolean "important"
    t.date "date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["level_id"], name: "index_price_level_hits_on_level_id"
  end

  create_table "price_levels", force: :cascade do |t|
    t.string "ticker", null: false
    t.decimal "value", precision: 20, scale: 4
    t.float "accuracy"
    t.integer "period"
    t.string "kind"
    t.boolean "important"
    t.boolean "manual"
    t.date "dates", array: true
    t.integer "total_volume"
    t.integer "average_volume"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "price_signal_results", force: :cascade do |t|
    t.string "ticker", null: false
    t.bigint "signal_id", null: false
    t.boolean "entered"
    t.boolean "stopped"
    t.float "d1_close"
    t.float "d1_max"
    t.float "d2_close"
    t.float "d2_max"
    t.float "w1_close"
    t.float "w1_max"
    t.float "w1_max_close"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["signal_id"], name: "index_price_signal_results_on_signal_id"
  end

  create_table "price_signals", force: :cascade do |t|
    t.string "ticker", null: false
    t.date "date", null: false
    t.date "base_date"
    t.string "kind", null: false
    t.string "direction", null: false
    t.boolean "exact"
    t.float "accuracy"
    t.jsonb "data"
    t.datetime "created_at"
    t.decimal "enter", precision: 20, scale: 4
    t.decimal "stop", precision: 20, scale: 4
    t.float "stop_size"
    t.text "interval", default: "day"
    t.time "time"
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
    t.boolean "current"
    t.index ["ticker", "date"], name: "index_price_targets_on_ticker_and_date", unique: true
  end

  create_table "prices", primary_key: "ticker", id: :string, force: :cascade do |t|
    t.decimal "value", precision: 20, scale: 4
    t.datetime "updated_at"
    t.datetime "last_at"
    t.string "source"
    t.decimal "low", precision: 20, scale: 4
    t.integer "volume"
    t.index ["ticker"], name: "index_prices_on_ticker", unique: true
  end

  create_table "public_signals", force: :cascade do |t|
    t.string "ticker", null: false
    t.string "source", null: false
    t.date "date"
    t.decimal "price", precision: 20, scale: 4
    t.integer "score"
    t.datetime "created_at"
    t.text "post_title"
    t.text "post_author"
    t.integer "post_comments_count"
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

  create_table "stats", primary_key: "ticker", id: :string, force: :cascade do |t|
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
    t.string "peers", array: true
    t.float "last_insider_buy_price"
    t.jsonb "extra"
  end

  add_foreign_key "price_level_hits", "price_levels", column: "level_id"
  add_foreign_key "price_signal_results", "price_signals", column: "signal_id"
end
