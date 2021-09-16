class Instrument < ApplicationRecord
  self.inheritance_column = nil

  has_many :candles,                       foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :aggregates,                    foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :indicators_history,            foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all, class_name: 'DateIndicators'
  has_many :day_candles, -> { day },       foreign_key: 'ticker', inverse_of: :instrument, class_name: 'Candle'
  has_many :m1_candles,                    foreign_key: 'ticker', inverse_of: :instrument, class_name: 'Candle::M1', dependent: :delete_all
  has_many :price_targets,                 foreign_key: 'ticker', inverse_of: :instrument
  has_many :signal_results,                foreign_key: 'ticker', inverse_of: :instrument, class_name: 'PriceSignalResult', dependent: :delete_all
  has_many :signals,                       foreign_key: 'ticker', inverse_of: :instrument, class_name: 'PriceSignal', dependent: :delete_all
  has_many :recommendations,               foreign_key: 'ticker', inverse_of: :instrument
  has_many :insider_transactions,          foreign_key: 'ticker', inverse_of: :instrument
  has_many :level_hits,                    foreign_key: 'ticker', inverse_of: :instrument, class_name: 'PriceLevelHit', dependent: :delete_all
  has_many :levels,                        foreign_key: 'ticker', inverse_of: :instrument, class_name: 'PriceLevel', dependent: :delete_all
  has_many :insider_transactions,          foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :insider_summaries,             foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :institution_holdings,          foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :option_items,                  foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :option_item_specs,             foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :arbitrage_cases,               foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :orders,                        foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :operations,                    foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :extremums,                     foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :spikes,                        foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :splits,                        foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all

  has_one :recommendation, -> { current }, foreign_key: 'ticker', inverse_of: :instrument
  has_one :price_target,   -> { current }, foreign_key: 'ticker', inverse_of: :instrument
  has_one :aggregate,      -> { current }, foreign_key: 'ticker', inverse_of: :instrument
  has_one :indicators,     -> { current }, foreign_key: 'ticker', inverse_of: :instrument, class_name: 'DateIndicators'
  has_one :price,                          foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete
  has_one :info, class_name: 'Stats',      foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete
  has_one :portfolio_item,                 foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete
  has_one :insider_aggregate,              foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete
  has_one :orderbook,                      foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete

  validates_presence_of :ticker, :name

  scope :with_flag, -> flag { where "? = any(flags)", flag }
  scope :tinkoff, -> { with_flag 'tinkoff' }
  scope :premium, -> { with_flag 'premium' }
  scope :spb, -> { where "'spb' = any(flags)" }
  scope :iex, -> { where "'iex' = any(flags)" }
  scope :iex_sourceable, -> { where.not iex_ticker: nil }
  scope :non_iex, -> { where iex_ticker: nil }
  scope :usd, -> { where currency: 'USD' }
  scope :eur, -> { where currency: 'EUR' }
  scope :rub, -> { where currency: 'RUB' }
  scope :stocks, -> { where type: 'Stock' }
  scope :funds, -> { where type: 'Fund' }
  scope :non_usd, -> { where.not currency: 'USD' }
  scope :abc, -> { order :ticker }
  scope :in_set, -> key { where ticker: InstrumentSet.get(key)&.symbols if key && key.to_s != 'all' }
  scope :main, -> { in_set :main }
  scope :small, -> { in_set :small }
  scope :for_tickers, -> tickers { where ticker: tickers.map(&:upcase) }
  scope :with_alarm, -> { joins(:levels).where(levels: { manual: true }) }
  scope :before, -> ticker { where 'instruments.ticker < ?', ticker }
  scope :after, -> ticker { where 'instruments.ticker >= ?', ticker }

  scope :mature, -> { where first_date: MatureDate }
  scope :with_first_date, -> { where.not first_date: nil }
  scope :without_first_date, -> { where first_date: nil }

  scope :vtb_spb_long, -> { where "stats.extra->>'vtb_list_2' = 'true'" }
  scope :vtb_moex_short, -> { where "stats.extra->>'vtb_can_short' = 'true'" }
  scope :vtb_iis, -> { where "stats.extra->>'vtb_on_iis' = 'true'" }


  MatureDate = Current.y2017
  DateSelectors = %w[today yesterday] + %w[d1 d2 d3 d4 d5 d6 d6 d7 w1 w2 m1 week month].map { |period| "#{period}_ago" }

  DateSelectors.each do |selector|
    define_method("#{selector}") do
      instance_variable_get("@#{selector}") ||
      instance_variable_set("@#{selector}", day_candles!.find_date(Current.send(selector))  )
    end
  end

  def feb19         = @feb19 ||= day_candles!.find_date(Current.feb19)
  def mar23         = @mar23 ||= day_candles!.find_date(Current.mar23)
  def nov06         = @nov06 ||= day_candles!.find_date(Current.nov06)
  def y2017         = @y2017 ||= day_candles!.find_date(Current.y2017)
  def y2018         = @y2018 ||= day_candles!.find_date(Current.y2018)
  def y2019         = @y2019 ||= day_candles!.find_date(Current.y2019)
  def y2020         = @y2020 ||= day_candles!.find_date(Current.y2020)
  def y2021         = @y2021 ||= day_candles!.find_date(Current.y2021)
  def last          = @last  ||= price!.last_at && yesterday_candle&.close_time ? (price!.last_at < yesterday_candle.close_time ? yesterday_candle.close : price!.value) : price!.value
  def last_low      = @last_low ||= price!.low
  def last_or_open  = last || today_open

  %w[usd eur rub].each { |currency| define_method("#{currency}?") { self.currency == currency.upcase } }

  %w[low high open close volume volatility volatility_range direction].each do |selector|
    (DateSelectors + %w[feb19 mar23 nov06 y2017 y2018 y2019 y2020 y2021]).each do |date|
      define_method("#{date}_#{selector}") { send(date).try(selector) }
      if selector.in? %w[low high open close]
        define_method("#{date}_#{selector}_rel")  { |curr_price = 'last'| rel_diff "#{date}_#{selector}", curr_price }
        define_method("#{date}_#{selector}_diff") { |curr_price = 'last'|     diff "#{date}_#{selector}", curr_price }
      end
    end
  end

  attribute :current_price_selector, default: "last"
  def base_price = send(current_price_selector)

  def diff(old_price, new_price = current_price_selector)
    old_price, new_price = send(old_price), send(new_price)
    new_price - old_price if old_price && new_price
  end

  def rel_diff(old_price, new_price = current_price_selector, default: nil)
    old_price, new_price = send(old_price), send(new_price)
    old_price && new_price ? new_price / old_price - 1.0 : default
  end

  def rel_diff_value(old_price_value, new_price = current_price_selector)
    new_price_value = send(new_price)
    new_price_value / old_price_value - 1.0 if old_price_value && new_price_value
  end

  def gain_since_close = rel_diff(:d1_ago_close, :last, default: 0)

  def price_on!(date) = day_candles!.find_date(date)
  def price_on(date) = day_candles!.find_date_before(date.to_date + 1)
  def price_on_or_before(date) = day_candles!.find_date_or_before(date)

  alias gain_since rel_diff_value

  def logo_path = Pathname("public/logos/#{ticker}.png")
  def check_logo = update_column(:has_logo, logo_path.exist?)

  def price! = Current.prices_cache&.for_instrument(self) || price || create_price!
  def day_candles! = Current.day_candles_cache ? Current.day_candles_cache.scope_to_instrument(self) : day_candles
  def info! = info || create_info

  def today_candle = day_candles!.find_date(Current.date)
  def yesterday_candle = day_candles!.find_date(Current.yesterday)

  def tinkoff? = flags.include?('tinkoff')
  def iex? = info.present?
  def premium? = flags.include?('premium')
  def fund? = type == 'Fund'
  def stock? = type == 'Stock'
  def nasdaq? = exchange_name == 'NASDAQ'
  def exchange_name = rub? ? 'MOEX' : exchange
  def moex? = rub?
  def moex_2nd? = MoexSecondary.include?(ticker)
  def marginal? = info&.vtb_long_risk != nil

  def market_work_period = moex_2nd? ? Current.ru_2nd_market_work_period : moex? ? Current.ru_market_work_period : Current.us_market_work_period
  def market_open? = market_work_period.include?(Time.current)

  MoexSecondary = %w[AGRO AMEZ RNFT ETLN FESH KRKNP LNTA MTLRP OKEY SIBN SMLT].to_set

  def to_s = ticker
  def exchange_ticker = "#{exchange}:#{ticker}".upcase
  def global_iex_ticker = rub?? "#{ticker}-RX" : iex_ticker

  def lowest_body_in(period) = day_candles!.find_dates_in(period).min_by(&:range_low)

  after_create def fix_iex_ticker
    return update! iex_ticker: nil if not usd?
    return update! iex_ticker: self.class.iex_ticker_for(ticker)
  end

  def set_first_date!
    first_candle_date = candles.day.asc.first&.date
    first_candle_date = nil if first_candle_date.to_s == MatureDate.to_s
    update! first_date: first_candle_date
  end

  def recent_low(days: 5)  = candles.day.order(:date).last(days).map(&:low).min
  def recent_high(days: 5) = candles.day.order(:date).last(days).map(&:high).max


  class << self
    def get(ticker = nil, figi: nil)
      return ticker if self === ticker
      figi ? find_by_figi(figi) : find_by_ticker(ticker.to_s.upcase)
    end

    def get_all(tickers)
      tickers.first.is_a?(self) ? tickers : where(ticker: tickers)
    end

    def get_by_iex_ticker(iex_ticker)
      find_by_iex_ticker(iex_ticker.to_s.upcase)
    end

    def get!(ticker = nil, figi: nil)
      get(ticker, figi: figi) || raise(ActiveRecord::RecordNotFound, "Instrument '#{ticker || figi}' does not exist!")
    end

    alias [] get
    def to_proc = -> ticker { get ticker }

    def reject_missing(tickers) = Instrument.for_tickers(tickers).pluck(:ticker)
    def normalize(records) = self === records.first ? records : records.map { |ticker| self[ticker] }.compact

    def tickers = @tickers ||= pluck(:ticker).to_set
    def defined?(ticker) = tickers.include?(ticker)

    IEX_TICKERS = { 'KAP@GS' => nil }
    def iex_ticker_for(ticker) = IEX_TICKERS.include?(ticker) ? IEX_TICKERS[ticker] : (ticker.include?('@GS') ? nil : ticker.sub(/\.US|@US/, ''))

    def moex_liquid_tickers = joins(:info).vtb_moex_short.pluck(:ticker)
    def moex_illiquid_tickers = rub.pluck(:ticker) - moex_liquid_tickers
  end

  concerning :Filters do
    def down_in_2021? = y2021_open_rel.to_f < 0
  end

  def last_insider_buy
    insider_transactions.buys.market_only.order(:date).last
  end

  def on_close_change(date: Current.yesterday)
    # candle50 = Candle::M5.find_by(ticker: ticker, date: date, time: '19:50')
    # candle55 = Candle::M5.find_by(ticker: ticker, date: date, time: '19:55')
    # (candle55.close - candle50.open) / candle50.open if candle50 && candle55

    Candle::M5.find_by(ticker: ticker, date: date, time: '19:55')&.rel_change
  end
end

__END__
Instrument.find_each &:check_logo
Instrument.find_each &:price!

Instrument['TGC'].destroy

Candle.day.where(ticker: 'BGS', date: Current.date)
Instrument.get('BGS').day_candles.where(date: Current.date)
Instrument.get('CHK').destroy
Instrument.get('CCL').today_open
Instrument.join(:info).count

Instrument.get('AAN').update! first_date: '2020-11-25'
