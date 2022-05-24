class Instrument < ApplicationRecord
  self.inheritance_column = nil

  has_many :candles,                         foreign_key: 'ticker', inverse_of: :instrument_record, dependent: :delete_all
  has_many :day_candles,                     foreign_key: 'ticker', inverse_of: :instrument_record, class_name: 'Candle'
  has_many :m1_candles,                      foreign_key: 'ticker', inverse_of: :instrument_record, dependent: :delete_all, class_name: 'Candle::M1'
  has_many :m3_candles,                      foreign_key: 'ticker', inverse_of: :instrument_record, dependent: :delete_all, class_name: 'Candle::M3'
  has_many :m5_candles,                      foreign_key: 'ticker', inverse_of: :instrument_record, dependent: :delete_all, class_name: 'Candle::M5'
  has_many :signal_results,                  foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all, class_name: 'PriceSignalResult'
  has_many :signals,                         foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all, class_name: 'PriceSignal'
  has_many :price_targets,                   foreign_key: 'ticker', inverse_of: :instrument
  has_many :recommendations,                 foreign_key: 'ticker', inverse_of: :instrument
  has_many :insider_transactions,            foreign_key: 'ticker', inverse_of: :instrument
  has_many :level_hits,                      foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all, class_name: 'PriceLevelHit'
  has_many :levels,                          foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all, class_name: 'PriceLevel'
  has_many :insider_transactions,            foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :insider_summaries,               foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :institution_holdings,            foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :option_items,                    foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :option_item_specs,               foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :arbitrage_cases,                 foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :orders,                          foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :operations,                      foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :extremums,                       foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :splits,                          foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :missing_dates,                   foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :watched_targets,                 foreign_key: 'ticker', dependent: :delete_all

  has_one :recommendation, -> { current },   foreign_key: 'ticker', inverse_of: :instrument
  has_one :price_target,   -> { current },   foreign_key: 'ticker', inverse_of: :instrument
  has_one :price,                            foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete
  has_one :portfolio_item,                   foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete
  has_one :insider_aggregate,                foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete
  has_one :orderbook,                        foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete
  has_one :future,                           foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete
  has_one :annotation,                       foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete, class_name: 'InstrumentAnnotation'

  has_one :info_record,                      foreign_key: 'ticker', inverse_of: :instrument_record, dependent: :delete, class_name: 'InstrumentInfo'
  has_one :aggregate_record,                 foreign_key: 'ticker', inverse_of: :instrument_record, dependent: :delete, class_name: 'Aggregate'
  has_one :indicators_record, -> { current },foreign_key: 'ticker', inverse_of: :instrument_record, class_name: 'DateIndicators'

  has_many :indicators_history,              foreign_key: 'ticker', inverse_of: :instrument_record, dependent: :delete_all, class_name: 'DateIndicators'
  has_many :spikes,                          foreign_key: 'ticker', inverse_of: :instrument_record, dependent: :delete_all

  scope :with_flag, -> flag { where "? = any(flags)", flag }
  scope :tinkoff, -> { with_flag 'tinkoff' }
  scope :premium, -> { with_flag 'premium' }
  scope :spb, -> { where "'spb' = any(flags)" }
  scope :iex, -> { where "'iex' = any(flags)" }
  scope :iex_sourceable, -> { where.not iex_ticker: nil }
  scope :non_iex, -> { where iex_ticker: nil }
  scope :traded_on, -> currency { where currency: currency.to_s.upcase }
  scope :intraday_traded_on, -> currency { traded_on(currency).send(currency.to_sym == :usd ? :current : :itself) }
  scope :usd, -> { where currency: 'USD' }
  scope :eur, -> { where currency: 'EUR' }
  scope :rub, -> { where currency: 'RUB' }
  scope :non_usd, -> { where.not currency: 'USD' }
  scope :non_eur, -> { where.not currency: 'EUR' }
  scope :stocks, -> { where type: 'Stock' }
  scope :currencies, -> { where type: 'Currency' }
  scope :futures, -> { where type: 'Future' }
  scope :funds, -> { where type: 'Fund' }
  scope :abc, -> { order :ticker }
  scope :in_set, -> key { where ticker: InstrumentSet.get(key)&.symbols if key && key.to_s != 'all' }
  scope :in_ticker_set, -> key { where ticker: TickerSet.get(key).tickers }
  scope :main, -> { in_set :main }
  scope :current, -> { in_ticker_set :current }
  scope :small, -> { in_set :small }
  scope :for_tickers, -> tickers { where ticker: tickers.map(&:upcase) }
  scope :with_alarm, -> { joins(:levels).where(levels: { manual: true }) }
  scope :before, -> ticker { where 'instruments.ticker < ?', ticker }
  scope :after, -> ticker { where 'instruments.ticker >= ?', ticker }
  scope :mature, -> { where first_date: MatureDate }
  scope :with_first_date, -> { where.not first_date: nil }
  scope :without_first_date, -> { where first_date: nil }
  scope :vtb_spb_long, -> { where "instrument_infos.extra->>'vtb_list_2' = 'true'" }
  scope :vtb_moex_short, -> { where "instrument_infos.extra->>'vtb_can_short' = 'true'" }
  scope :vtb_iis, -> { where "instrument_infos.extra->>'vtb_on_iis' = 'true'" }
  scope :liquid, -> { rub.where.not ticker: MarketInfo::MoexIlliquid }
  scope :active,  -> { where active: true, type: 'Stock' }
  scope :active!, -> { where active: true }

  validates_presence_of :ticker, :name

  after_create { |inst| SetIexTickers.process(inst) }

  attribute :current_price_selector, default: :last


  MatureDate = Current.y2017
  DateSelectors = %w[today yesterday last_day prev_day] + %w[d1 d2 d3 d4 d5 d6 d7 w1 w2 m1 m3 y1 week month year].map { |period| "#{period}_ago" }


  DateSelectors.each do |selector|
    define_method(selector) do
      instance_variable_set("@#{selector}", day_candles!.find_date(calendar.send(selector))  )
      # instance_variable_set("@#{selector}", day_candles!.find_date(Current.market_for(self).send(selector))  )
    end
  end

  def y2017         = day_candles!.find_date(Current.y2017)
  def y2018         = day_candles!.find_date(Current.y2018)
  def y2019         = day_candles!.find_date(Current.y2019)
  def y2020         = day_candles!.find_date(Current.y2020)
  def y2021         = day_candles!.find_date(Current.y2021)
  def y2022         = day_candles!.find_date(Current.y2022)
  def last          = price!.last_at && yesterday_candle&.close_time ? (price!.last_at < yesterday_candle.close_time ? yesterday_candle.close : price!.value) : price!.value
  def last!         = price!.value
  def last_low      = price!.low
  def last_or_open  = last || today_open
  def last_using(interval = '1min') = candles_for(interval).last&.close

  %w[usd eur rub].each { |currency| define_method("#{currency}?") { self.currency == currency.upcase } }

  %w[low high open close volume volatility volatility_range direction].each do |selector|
    (DateSelectors + %w[y2017 y2018 y2019 y2020 y2021 y2022]).each do |date|
      define_method("#{date}_#{selector}") { send(date).try(selector) }
      if selector.in? %w[low high open close]
        define_method("#{date}_#{selector}_rel")  { |curr_price = 'last'| rel_diff "#{date}_#{selector}", curr_price }
        define_method("#{date}_#{selector}_diff") { |curr_price = 'last'|     diff "#{date}_#{selector}", curr_price }
      end
    end
  end

  %w[d2 d3 d4 d5 d6 d7 w1 w2 m1 m3 y1 week month year].each do |date_selector|
    define_method("#{date_selector}_period_low")  { ExtremumCache.get(ticker, Current.send("#{date_selector}_ago"), :low) }
    define_method("#{date_selector}_period_high") { ExtremumCache.get(ticker, Current.send("#{date_selector}_ago"), :high) }
    define_method("change_since_#{date_selector}_low")  { gain_since(send("#{date_selector}_period_low"),  :last) }
    define_method("change_since_#{date_selector}_high") { gain_since(send("#{date_selector}_period_high"), :last) }
  end

  def base_price = send(current_price_selector)
  def get_price(selector) = selector.is_a?(Symbol) || selector.is_a?(String) ? send(selector) : selector

  def diff(old_price, new_price = current_price_selector)
    old_price, new_price = get_price(old_price), get_price(new_price)
    new_price - old_price if old_price && new_price
  end

  def rel_diff(base_price, new_price = current_price_selector, default: nil)
    base_price, new_price = get_price(base_price), get_price(new_price)
    new_price / base_price - 1.0 rescue default
  end
  alias gain_since rel_diff

  def change_since_close   = gain_since(:prev_day_close, :last)
  def change_in_3d         = gain_since(:d3_ago_close, :last)
  def change_to_ema_20     = gain_since(:last, last_indicators&.ema_20)
  def change_to_ema_50     = gain_since(:last, last_indicators&.ema_50)
  def change_to_ema_200    = gain_since(:last, last_indicators&.ema_200)

  def price_on!(date) = day_candles!.find_date(date)
  def price_on(date) = day_candles!.find_date_or_before(date.to_date + 1)
  def price_on_or_before(date) = day_candles!.find_date_or_before(date)

  def d1_change = gain_since(:d2_ago_close, :d1_ago_close)
  def price_change = price!.change rescue 0
  def stored_gain_since(date_specifier) = (date_specifier.blank? || date_specifier == 'last') ? price_change : aggregate.gains[date_specifier]

  def calendar = MarketCalendar.for(self)

  def logo_path = Pathname("public/logos/#{ticker}.png")
  def check_logo = update_column(:has_logo, logo_path.exist?)

  def price! = PriceCache.for_instrument(self) || price || create_price!
  def day_candles! = CandleCache.for_instrument(self)
  def candles_for(interval) = Candle.interval_class_for(interval).where(ticker: ticker)

  def info = PermaCache.info(ticker)
  alias info! info
  def aggregate = PermaCache.aggregate(ticker)
  def indicators = PermaCache.indicator(ticker)
  def last_indicators = !indicators || indicators.date == Current.date ? indicators : indicators.last
  def annotation! = annotation || create_annotation

  def today_candle = day_candles!.find_date(calendar.today)
  def yesterday_candle = day_candles!.find_date(calendar.yesterday)

  def tinkoff? = flags.include?('tinkoff')
  def iex? = info.present?
  def premium? = flags.include?('premium')
  def fund? = type == 'Fund'
  def stock? = type == 'Stock'
  def nasdaq? = exchange_name == 'NASDAQ'
  def exchange_name = rub? ? 'MOEX' : exchange
  def moex? = rub?
  def moex_2nd? = MarketInfo::Moex2.include?(ticker)
  def marginal? = info&.tinkoff_long_risk != nil
  def shortable? = info&.tinkoff_can_short?
  def liquid? = !illiquid?
  def illiquid? = rub? && MarketInfo::MoexIlliquid.include?(ticker)
  def ignored? = rub? && MarketInfo::MoexIgnored.include?(ticker)
  def watched? = InstrumentSet.watched?(ticker)
  def favorite? = TickerSet.favorites.include?(ticker)

  def market_work_period = moex_2nd? ? Current.ru_2nd_market_work_period : moex? ? Current.ru_market_work_period : Current.us_market_work_period
  def market_open? = market_work_period.include?(Time.current)

  def time_zone  = calendar.timezone
  def time       = calendar.time
  def opening_hhmm  = MarketInfo.ticker_opening_time(ticker)
  def closing_hhmm  = MarketInfo.ticker_closing_time(ticker)
  def opening_time_without_date = Current.zero_day.change(MarketInfo.ticker_opening_hour_min ticker)
  def today_opening = time.change(MarketInfo.ticker_opening_hour_min ticker)
  def today_closing = time.change(MarketInfo.ticker_closing_hour_min ticker)
  def opening_on(date) = date.in_time_zone(time_zone).to_time.change(MarketInfo.ticker_opening_hour_min ticker)
  def closing_on(date) = date.in_time_zone(time_zone).to_time.change(MarketInfo.ticker_closing_hour_min ticker)


  def to_s = ticker
  def exchange_ticker = "#{exchange}:#{ticker}".upcase
  def global_iex_ticker = rub?? "#{ticker}-RX" : eur?? ticker.gsub('@DE', '-GF') : iex_ticker
  def clean_ticker = ticker.gsub(/@\w\w/, '')

  def lowest_body_in(period) = day_candles!.find_dates_in(period).min_by(&:range_low)

  def set_first_date!
    first_candle_date = candles.day.asc.first&.date
    first_candle_date = nil if first_candle_date.to_s == MatureDate.to_s
    update! first_date: first_candle_date
  end

  def recent_low(days: 5)  = candles.day.order(:date).last(days).map(&:low).min
  def recent_high(days: 5) = candles.day.order(:date).last(days).map(&:high).max

  def deactivate = update(active: false)
  def activate   = update(active: true)

  def today! = today || day_candles.build(date: Current.date, time: '07:00', ongoing: true, source: 'tinkoff')


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

    def normalize_ticker(ticker)
      case
        when ticker == nil then nil
        when ticker.is_a?(String) then ticker
        when ticker.respond_to?(:ticker) then ticker.ticker
        else ticker.to_s.upcase
      end
    end

    def normalize(records)
      case
        when records.blank? then []
        when records.first.is_a?(self) then records
        when records.first.respond_to?(:instrument) then records.map(&:instrument)
        else records.map { self[_1] }.compact
      end
    end

    memoize def tickers = pluck(:ticker).to_set
    def defined?(ticker) = tickers.include?(ticker)

    # IEX_TICKERS = { 'KAP@GS' => nil }
    # def iex_ticker_for(ticker) = IEX_TICKERS.include?(ticker) ? IEX_TICKERS[ticker] : (ticker.include?('@GS') ? nil : ticker.sub(/\.US|@US/, ''))

    def moex_liquid_tickers = joins(:info).vtb_moex_short.pluck(:ticker)
    def moex_illiquid_tickers = rub.pluck(:ticker) - moex_liquid_tickers

    def activate_all = update_all(active: true)
    def deactivate_all = update_all(active: false)
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
Instrument['TGC'].destroy
Benchmark.ms { prices = Price.where(ticker: t).to_a }
