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

ActiveRecord::Schema.define(version: 2022_02_07_131353) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "aggregates", force: :cascade do |t|
    t.string "ticker", null: false
    t.date "date", null: false
    t.boolean "current", default: false, null: false
    t.decimal "close", precision: 20, scale: 4
    t.float "close_change"
    t.integer "days_up"
    t.date "lowest_day_date"
    t.float "lowest_day_gain"
    t.jsonb "data", default: {}
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "d1_money_volume"
    t.float "y1_high_change"
    t.float "y3_high_change"
    t.date "y1_high_date"
    t.date "y3_high_date"
    t.float "y1_low_change"
    t.float "y3_low_change"
    t.date "y1_low_date"
    t.date "y3_low_date"
    t.string "change_map"
    t.index ["current"], name: "index_aggregates_on_current"
    t.index ["ticker", "date"], name: "index_aggregates_on_ticker_and_date", unique: true
    t.index ["ticker"], name: "index_aggregates_on_ticker"
  end

  create_table "arbitrage_cases", force: :cascade do |t|
    t.string "ticker"
    t.decimal "percent", precision: 8, scale: 2
    t.boolean "long"
    t.boolean "delisted"
    t.string "exchange_code"
    t.decimal "spb_bid", precision: 20, scale: 4
    t.integer "spb_bid_size"
    t.decimal "spb_ask", precision: 20, scale: 4
    t.integer "spb_ask_size"
    t.decimal "foreign_bid", precision: 20, scale: 4
    t.integer "foreign_bid_size"
    t.decimal "foreign_ask", precision: 20, scale: 4
    t.integer "foreign_ask_size"
    t.date "date"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["date"], name: "index_arbitrage_cases_on_date"
    t.index ["ticker", "date"], name: "index_arbitrage_cases_on_ticker_and_date"
    t.index ["ticker"], name: "index_arbitrage_cases_on_ticker"
  end

  create_table "candles", force: :cascade do |t|
    t.string "ticker"
    t.string "interval", null: false
    t.time "time", null: false
    t.decimal "open", precision: 20, scale: 4, null: false
    t.decimal "close", precision: 20, scale: 4, null: false
    t.decimal "high", precision: 20, scale: 4, null: false
    t.decimal "low", precision: 20, scale: 4, null: false
    t.integer "volume", null: false
    t.string "source"
    t.date "date"
    t.boolean "ongoing", default: false
    t.boolean "analyzed"
    t.decimal "prev_close", precision: 20, scale: 4
    t.index ["ticker", "interval", "date"], name: "index_candles_on_ticker_interval_date"
    t.index ["ticker", "interval", "date"], name: "uniq_ticker_date_for_days", where: "((\"interval\")::text = 'day'::text)"
    t.index ["ticker"], name: "index_candles_on_ticker"
  end

  create_table "candles_d1_tinkoff", id: :bigint, default: -> { "nextval('candles_d1_tinkoff_seq'::regclass)" }, force: :cascade do |t|
    t.string "ticker", null: false
    t.string "interval", default: "day", null: false
    t.date "date", null: false
    t.time "time", null: false
    t.decimal "open", precision: 20, scale: 4, null: false
    t.decimal "close", precision: 20, scale: 4, null: false
    t.decimal "high", precision: 20, scale: 4, null: false
    t.decimal "low", precision: 20, scale: 4, null: false
    t.integer "volume", null: false
    t.string "source", default: "tinkoff", null: false
    t.boolean "ongoing", default: false, null: false
    t.boolean "analyzed", default: false, null: false
    t.decimal "prev_close", precision: 20, scale: 4
    t.index ["ticker", "date"], name: "candles_d1_tinkoff_ticker_interval_date_idx"
    t.index ["ticker"], name: "candles_d1_tinkoff_ticker_idx"
  end

  create_table "candles_h1", force: :cascade do |t|
    t.string "ticker"
    t.string "interval", null: false
    t.time "time", null: false
    t.decimal "open", precision: 20, scale: 4, null: false
    t.decimal "close", precision: 20, scale: 4, null: false
    t.decimal "high", precision: 20, scale: 4, null: false
    t.decimal "low", precision: 20, scale: 4, null: false
    t.integer "volume", null: false
    t.string "source"
    t.date "date"
    t.boolean "ongoing", default: false
    t.boolean "analyzed"
    t.decimal "prev_close", precision: 20, scale: 4
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
    t.decimal "prev_close", precision: 20, scale: 4
    t.index ["ticker", "date"], name: "candles_m1_ticker_interval_date_idx"
    t.index ["ticker"], name: "candles_m1_ticker_idx"
  end

  create_table "candles_m3", force: :cascade do |t|
    t.string "ticker"
    t.string "interval", limit: 4, null: false
    t.date "date", null: false
    t.time "time", null: false
    t.decimal "open", precision: 20, scale: 4, null: false
    t.decimal "close", precision: 20, scale: 4, null: false
    t.decimal "high", precision: 20, scale: 4, null: false
    t.decimal "low", precision: 20, scale: 4, null: false
    t.integer "volume", null: false
    t.string "source", null: false
    t.boolean "ongoing", default: false, null: false
    t.boolean "analyzed", default: false, null: false
    t.decimal "prev_close", precision: 20, scale: 4
    t.index ["ticker", "date"], name: "candles_m3_ticker_date_idx"
    t.index ["ticker"], name: "candles_m3_ticker_idx"
  end

  create_table "candles_m5", force: :cascade do |t|
    t.string "ticker"
    t.string "interval", limit: 4, null: false
    t.time "time", null: false
    t.decimal "open", precision: 20, scale: 4, null: false
    t.decimal "close", precision: 20, scale: 4, null: false
    t.decimal "high", precision: 20, scale: 4, null: false
    t.decimal "low", precision: 20, scale: 4, null: false
    t.integer "volume", null: false
    t.string "source"
    t.date "date"
    t.boolean "ongoing", default: false
    t.boolean "analyzed", default: false
    t.decimal "prev_close", precision: 20, scale: 4
    t.index ["ticker", "interval", "date"], name: "candles_5m_ticker_interval_date_idx"
    t.index ["ticker", "interval", "date"], name: "candles_5m_ticker_interval_date_idx1", where: "((\"interval\")::text = 'day'::text)"
    t.index ["ticker"], name: "candles_5m_ticker_idx"
  end

  create_table "extremums", force: :cascade do |t|
    t.string "ticker"
    t.date "date"
    t.decimal "value", precision: 20, scale: 2
    t.decimal "close", precision: 20, scale: 2
    t.string "kind"
    t.integer "period"
    t.integer "last_low_in"
    t.integer "last_high_in"
    t.datetime "created_at"
    t.index ["date"], name: "index_extremums_on_date"
    t.index ["ticker"], name: "index_extremums_on_ticker"
  end

  create_table "indicators", id: :bigint, default: -> { "nextval('date_indicators_id_seq'::regclass)" }, force: :cascade do |t|
    t.string "ticker", null: false
    t.date "date", null: false
    t.boolean "current", default: false, null: false
    t.decimal "ema_20", precision: 20, scale: 4
    t.decimal "ema_50", precision: 20, scale: 4
    t.decimal "ema_200", precision: 20, scale: 4
    t.integer "ema_20_trend"
    t.integer "ema_50_trend"
    t.integer "ema_200_trend"
    t.decimal "ema_100", precision: 20, scale: 4
    t.integer "ema_100_trend"
    t.index ["current"], name: "index_date_indicators_on_current"
    t.index ["ticker", "current"], name: "index_date_indicators_on_ticker_and_current", where: "(current = true)"
    t.index ["ticker", "date"], name: "index_date_indicators_on_ticker_and_date", unique: true
    t.index ["ticker"], name: "index_date_indicators_on_ticker"
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
    t.bigint "shares"
    t.bigint "shares_final"
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

  create_table "instrument_annotations", force: :cascade do |t|
    t.string "ticker", null: false
    t.decimal "intraday_levels", precision: 20, scale: 4, array: true
    t.datetime "updated_at"
  end

  create_table "instruments", primary_key: "ticker", id: :string, force: :cascade do |t|
    t.string "isin"
    t.string "figi"
    t.string "currency"
    t.string "name", null: false
    t.string "type", default: "Stock", null: false
    t.integer "lot", default: 1
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

  create_table "missing_dates", force: :cascade do |t|
    t.string "ticker", null: false
    t.date "date", null: false
    t.index ["ticker", "date"], name: "index_missing_dates_on_ticker_date", unique: true
    t.index ["ticker"], name: "index_missing_dates_on_ticker"
  end

  create_table "news", force: :cascade do |t|
    t.string "title"
    t.string "body"
    t.string "ticker"
    t.string "tickers", array: true
    t.datetime "datetime"
    t.integer "external_id"
    t.string "url"
    t.string "source"
    t.datetime "created_at"
    t.index ["datetime"], name: "index_news_on_datetime"
    t.index ["tickers"], name: "index_news_on_tickers"
  end

  create_table "operations", force: :cascade do |t|
    t.string "ticker", null: false
    t.string "kind"
    t.string "status"
    t.datetime "datetime"
    t.integer "lots"
    t.integer "lots_executed"
    t.decimal "price", precision: 20, scale: 2
    t.decimal "payment", precision: 20, scale: 2
    t.decimal "commission", precision: 20, scale: 2
    t.string "currency"
    t.integer "trades_count"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "option_item_specs", force: :cascade do |t|
    t.string "code"
    t.string "side"
    t.string "ticker"
    t.date "date"
    t.decimal "strike", precision: 20, scale: 4
    t.datetime "created_at", precision: 6, null: false
    t.index ["code"], name: "option_item_specs_on_code", unique: true
  end

  create_table "option_items", force: :cascade do |t|
    t.string "code"
    t.string "ticker"
    t.string "side"
    t.date "date"
    t.decimal "strike", precision: 20, scale: 4
    t.integer "open_interest"
    t.integer "volume"
    t.decimal "open", precision: 20, scale: 4
    t.decimal "close", precision: 20, scale: 4
    t.datetime "created_at"
    t.date "updated_on"
    t.index ["code", "updated_on"], name: "code_date", unique: true
    t.index ["code"], name: "option_items_code"
  end

  create_table "orderbooks", force: :cascade do |t|
    t.string "ticker"
    t.jsonb "bids"
    t.jsonb "asks"
    t.decimal "last", precision: 20, scale: 4
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "status"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "account_id"
    t.string "ticker", null: false
    t.string "operation"
    t.string "kind"
    t.string "status"
    t.integer "lots"
    t.integer "lots_executed"
    t.decimal "price", precision: 20, scale: 4
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
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
    t.decimal "tinkoff_iis_average", precision: 20, scale: 4
    t.decimal "tinkoff_iis_yield", precision: 20, scale: 4
    t.decimal "tinkoff_average", precision: 20, scale: 4
    t.decimal "tinkoff_yield", precision: 20, scale: 4
  end

  create_table "price_level_hits", force: :cascade do |t|
    t.string "ticker", null: false
    t.bigint "level_id"
    t.decimal "level_value", precision: 20, scale: 4
    t.string "kind"
    t.boolean "exact"
    t.boolean "important"
    t.date "date"
    t.datetime "created_at", precision: 6, null: false
    t.string "source"
    t.boolean "manual"
    t.integer "ma_length"
    t.boolean "positive"
    t.boolean "continuation"
    t.float "close_distance"
    t.float "max_distance"
    t.integer "days_since_last"
    t.float "rel_vol"
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
    t.float "d3_close"
    t.float "d3_max"
    t.float "d4_close"
    t.float "d4_max"
    t.float "w1_close"
    t.float "w1_max"
    t.float "w2_close"
    t.float "w2_max"
    t.float "w3_close"
    t.float "w3_max"
    t.float "m1_close"
    t.float "m1_max"
    t.float "m2_close"
    t.float "m2_max"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["signal_id"], name: "index_price_signal_results_on_signal_id"
  end

  create_table "price_signal_strategies", force: :cascade do |t|
    t.string "signal"
    t.string "direction"
    t.daterange "period"
    t.numrange "change"
    t.numrange "spy_change"
    t.numrange "prev_1w_low"
    t.numrange "prev_2w_low"
    t.numrange "prev_1w_high"
    t.numrange "prev_2w_high"
    t.numrange "next_1d_change"
    t.numrange "next_1d_open"
    t.numrange "next_1d_close"
    t.integer "count"
    t.integer "entered_count"
    t.integer "stopped_count"
    t.float "d1_close"
    t.float "d1_max"
    t.float "d2_close"
    t.float "d2_max"
    t.float "d3_close"
    t.float "d3_max"
    t.float "d4_close"
    t.float "d4_max"
    t.float "w1_close"
    t.float "w1_max"
    t.float "w2_close"
    t.float "w2_max"
    t.float "w3_close"
    t.float "w3_max"
    t.float "m1_close"
    t.float "m1_max"
    t.float "m2_close"
    t.float "m2_max"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.numrange "volume_change"
    t.boolean "on_level"
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
    t.decimal "enter", precision: 20, scale: 4
    t.decimal "stop", precision: 20, scale: 4
    t.float "stop_size"
    t.text "interval", default: "day"
    t.time "time"
    t.boolean "on_level"
    t.float "volume_change"
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
    t.float "change"
    t.float "change_atr"
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

  create_table "settings", force: :cascade do |t|
    t.string "key"
    t.jsonb "value"
    t.datetime "updated_at"
  end

  create_table "spikes", force: :cascade do |t|
    t.string "ticker"
    t.date "date"
    t.float "spike"
    t.float "change"
    t.index ["date"], name: "index_spikes_on_date"
    t.index ["ticker"], name: "index_spikes_on_ticker"
  end

  create_table "splits", force: :cascade do |t|
    t.string "ticker"
    t.date "declared_date"
    t.date "ex_date"
    t.string "desc"
    t.float "ratio"
    t.integer "from_factor"
    t.integer "to_factor"
    t.datetime "created_at"
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
    t.integer "avg_volume"
    t.bigint "d5_money_volume"
    t.date "earning_dates", array: true
    t.float "avg_change"
    t.float "d5_marketcap_volume"
  end

  add_foreign_key "price_level_hits", "price_levels", column: "level_id"
  add_foreign_key "price_signal_results", "price_signals", column: "signal_id"
end
