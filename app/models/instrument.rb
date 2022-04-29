class Instrument < ApplicationRecord
  self.inheritance_column = nil

  has_many :candles,                       foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :day_candles, -> { day },       foreign_key: 'ticker', inverse_of: :instrument, class_name: 'Candle'
  has_many :m1_candles,                    foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all, class_name: 'Candle::M1'
  has_many :m3_candles,                    foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all, class_name: 'Candle::M3'
  has_many :m5_candles,                    foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all, class_name: 'Candle::M5'
  has_many :aggregates,                    foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_many :indicators_history,            foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all, class_name: 'DateIndicators'
  has_many :signal_results,                foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all, class_name: 'PriceSignalResult'
  has_many :signals,                       foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all, class_name: 'PriceSignal'
  has_many :price_targets,                 foreign_key: 'ticker', inverse_of: :instrument
  has_many :recommendations,               foreign_key: 'ticker', inverse_of: :instrument
  has_many :insider_transactions,          foreign_key: 'ticker', inverse_of: :instrument
  has_many :level_hits,                    foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all, class_name: 'PriceLevelHit'
  has_many :levels,                        foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all, class_name: 'PriceLevel'
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
  has_many :missing_dates,                 foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete_all
  has_one :recommendation, -> { current }, foreign_key: 'ticker', inverse_of: :instrument
  has_one :price_target,   -> { current }, foreign_key: 'ticker', inverse_of: :instrument
  has_one :aggregate,                      foreign_key: 'ticker', inverse_of: :instrument
  has_one :indicators,     -> { current }, foreign_key: 'ticker', inverse_of: :instrument, class_name: 'DateIndicators'
  has_one :price,                          foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete
  has_one :info, class_name: 'Stats',      foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete
  has_one :portfolio_item,                 foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete
  has_one :insider_aggregate,              foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete
  has_one :orderbook,                      foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete
  has_one :annotation,                     foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete, class_name: 'InstrumentAnnotation'
  has_one :future,                         foreign_key: 'ticker', inverse_of: :instrument, dependent: :delete


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
  scope :futures, -> { where type: 'Future' }
  scope :funds, -> { where type: 'Fund' }
  scope :non_usd, -> { where.not currency: 'USD' }
  scope :non_eur, -> { where.not currency: 'EUR' }
  scope :abc, -> { order :ticker }
  scope :in_set, -> key { where ticker: InstrumentSet.get(key)&.symbols if key && key.to_s != 'all' }
  scope :main, -> { in_set :main }
  scope :current, -> { in_set :current }
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
  scope :liquid, -> { rub.where.not ticker: MarketInfo::MoexIlliquid }

  scope :active, -> { where active: true, type: 'Stock' }

  validates_presence_of :ticker, :name

  after_create { |inst| SetIexTickers.process(inst) }

  attribute :current_price_selector, default: :last


  MatureDate = Current.y2017
  DateSelectors = %w[today yesterday last_day] + %w[d1 d2 d3 d4 d5 d6 d7 w1 w2 m1 m3 y1 week month year].map { |period| "#{period}_ago" }


  DateSelectors.each do |selector|
    define_method("#{selector}") do
      instance_variable_get("@#{selector}") ||
      instance_variable_set("@#{selector}", day_candles!.find_date(Current.send(selector))  )
    end
  end

  def y2017         = @y2017 ||= day_candles!.find_date(Current.y2017)
  def y2018         = @y2018 ||= day_candles!.find_date(Current.y2018)
  def y2019         = @y2019 ||= day_candles!.find_date(Current.y2019)
  def y2020         = @y2020 ||= day_candles!.find_date(Current.y2020)
  def y2021         = @y2021 ||= day_candles!.find_date(Current.y2021)
  def y2022         = @y2022 ||= day_candles!.find_date(Current.y2022)
  def last          = @last  ||= price!.last_at && yesterday_candle&.close_time ? (price!.last_at < yesterday_candle.close_time ? yesterday_candle.close : price!.value) : price!.value
  def last!         = @last  ||= price!.value
  def last_low      = @last_low ||= price!.low
  def last_or_open  = last || today_open
  def last_using(interval = '1min') = @last_alt ||= candles_for(interval).last&.close

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

  def change_since_close = gain_since(:yesterday_close, :last)
  def change_to_ema_20   = gain_since(:last, indicators.ema_20)
  def change_to_ema_50   = gain_since(:last, indicators.ema_50)
  def change_to_ema_200  = gain_since(:last, indicators.ema_200)
  def change_in_3d       = gain_since(:d3_ago_close, :last) 

  def price_on!(date) = day_candles!.find_date(date)
  def price_on(date) = day_candles!.find_date_before(date.to_date + 1)
  def price_on_or_before(date) = day_candles!.find_date_or_before(date)

  def d1_change = @d1_change ||= gain_since(:d2_ago_close, :d1_ago_close)
  def price_change = @price_change ||= price!.change rescue 0
  def stored_gain_since(date_specifier) = date_specifier.blank? || date_specifier == 'last' ? price_change : aggregate.gains[date_specifier]

  def logo_path = Pathname("public/logos/#{ticker}.png")
  def check_logo = update_column(:has_logo, logo_path.exist?)

  def price! = Current.prices_cache&.for_instrument(self) || price || create_price!
  def day_candles! = Current.day_candles_cache ? Current.day_candles_cache.scope_to_instrument(self) : day_candles
  def candles_for(interval) = Candle.interval_class_for(interval).where(ticker: ticker)

  def info! = info || create_info
  def annotation! = annotation || create_annotation

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
  def moex_2nd? = MarketInfo::Moex2.include?(ticker)
  def marginal? = info&.tinkoff_long_risk != nil
  def shortable? = info&.tinkoff_can_short?
  def liquid? = !illiquid?
  def illiquid? = rub? && MarketInfo::MoexIlliquid.include?(ticker)
  def very_illiquid? = rub? && MarketInfo::MoexVeryIlliquid.include?(ticker)
  def ignored? = rub? && MarketInfo::MoexIgnored.include?(ticker)
  def watched? = InstrumentSet.watched?(ticker)

  def market_work_period = moex_2nd? ? Current.ru_2nd_market_work_period : moex? ? Current.ru_market_work_period : Current.us_market_work_period
  def market_open? = market_work_period.include?(Time.current)

  def time_zone  = usd?? Current.est : Current.msk
  def time       = time_zone.now
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

  # after_create def fix_iex_ticker
  #   update! iex_ticker: usd? ? self.class.iex_ticker_for(ticker) : nil
  # end

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

  def update_today_candle_intraday(period = '1min')
    intraday_candles = candles_for(period).today.by_time.to_a
    return if intraday_candles.empty?
    today = today!
    today.update!(
      open:   intraday_candles.first.open,
      close:  intraday_candles.last.close,
      high:   intraday_candles.map(&:high).max,
      low:    intraday_candles.map(&:low).min,
      volume: intraday_candles.sum(&:volume),
    )
  end

  def update_larger_candles(date: Current.date)
    %w[5min].each do |interval|
      minutes_in_interval = Candle.interval_duration_in_mins(interval)
      day_open_time = opening_time_without_date

      last_mx_candle = candles_for(interval).on(date).order(:time).last
      last_mx_candle ||= candles_for(interval).on(date).build(time: day_open_time, open: yesterday_close, close: yesterday_close, high: yesterday_close, low: yesterday_close)

      m1_candles = candles_for('1min').on(date).since_time(last_mx_candle.time).order(:time).to_a
      m1_candles_index = m1_candles.index_by &:time
      time_intervals = MarketCalendar.periods_between(last_mx_candle.time, m1_candles.last&.time)

      grouped_intervals = time_intervals.in_groups_of(minutes_in_interval)
      grouped_intervals = grouped_intervals.map do |intervals|
        {
          start: intervals.first&.to_hhmm,
          periods: intervals.map { _1&.to_hhmm },
          candles: intervals.map { m1_candles_index[_1] },
        }
      end

      transaction do
        grouped_m1_candles = grouped_intervals.map do |interval_data|
          interval_data => { start:, periods:, candles: }
          candles = candles.compact
          # puts "-- build #{ticker} #{interval} on #{start} #{'NONE' if candles.none?}".white
          mx_candle = candles_for(interval).on(date).find_or_initialize_by(time: start)
          # next if mx_candle.updated_at > candles.map(&:updated_at).max

          mx_candle.instrument = self
          mx_candle.source     = 'virtual'
          mx_candle.interval   = interval
          mx_candle.prev_close = last_mx_candle.prev_close
          if candles.any?
            mx_candle.open       = candles.first.open
            mx_candle.close      = candles.last.open
            mx_candle.high       = candles.map(&:high).max
            mx_candle.low        = candles.map(&:low).min
            mx_candle.volume     = candles.sum(&:volume)
            mx_candle.ongoing    = candles.last&.ongoing?
            mx_candle.save!
            last_mx_candle = mx_candle
          else
            mx_candle.open       = last_mx_candle.open
            mx_candle.close      = last_mx_candle.close
            mx_candle.high       = last_mx_candle.high
            mx_candle.low        = last_mx_candle.low
            mx_candle.ongoing    = last_mx_candle.ongoing?
            mx_candle.volume     = 0
            mx_candle.save!
          end
        end
      end
    end
  end

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

    # IEX_TICKERS = { 'KAP@GS' => nil }
    # def iex_ticker_for(ticker) = IEX_TICKERS.include?(ticker) ? IEX_TICKERS[ticker] : (ticker.include?('@GS') ? nil : ticker.sub(/\.US|@US/, ''))

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
