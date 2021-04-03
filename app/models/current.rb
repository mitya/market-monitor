class Current < ActiveSupport::CurrentAttributes
  attribute :day_candles_cache, :prices_cache

  def date
    date = Time.current.hour < 7 ? Date.yesterday : Date.current
    date.on_weekend?? date.prev_weekday : date
  end
  alias today date

  def us_market_open?
    us_time = Time.find_zone!('Eastern Time (US & Canada)').now
    date.on_weekday? && us_time.to_s(:time) >= '16:30'
  end

  def yesterday = date.prev_weekday
  def d2_ago    = yesterday.prev_weekday
  def d3_ago    = d2_ago.prev_weekday
  def d4_ago    = d3_ago.prev_weekday
  def d5_ago    = d4_ago.prev_weekday
  def d6_ago    = d5_ago.prev_weekday
  def d7_ago    = d6_ago.prev_weekday
  def d10_ago   = d7_ago.prev_weekday.prev_weekday.prev_weekday
  def week_ago  = MarketCalendar.closest_weekday(1.week.ago.to_date)
  def month_ago = MarketCalendar.closest_weekday(1.month.ago.to_date)
  def feb19     = Date.new(2020,  2, 19)
  def mar23     = Date.new(2020,  3, 23)
  def nov06     = Date.new(2020, 11,  6)
  def y2019     = Date.new(2019,  1,  3)
  def y2020     = Date.new(2020,  1,  3)
  def y2021     = Date.new(2021,  1,  4)
  alias d1_ago yesterday
  alias w1_ago d5_ago
  alias w2_ago d10_ago
  alias m1_ago month_ago

  def weekdays_since(date) = date.upto(Current.yesterday).to_a.select(&:on_weekday?).reverse
  def last_n_weeks(n) = n.weeks.ago.to_date.upto(Current.yesterday).to_a.select(&:on_weekday?).reverse
  def last_2_weeks = last_n_weeks(2)

  def preload_day_candles_for(instruments)
    self.day_candles_cache = DayCandleCache.new(instruments, nil)
  end

  def preload_day_candles_with(instruments, extra_dates)
    self.day_candles_cache = DayCandleCache.new(instruments, extra_dates)
  end

  def preload_prices_for(instruments)
    self.prices_cache = PriceCache.new(instruments)
  end

  def in_usd(amount, currency)
    case currency
    when 'USD' then amount
    when 'EUR' then amount * 1.2
    when 'RUB' then amount / 76
    end
  end

  class PriceCache
    def initialize(instruments)
      @instruments = instruments
      @prices = InstrumentPrice.where(ticker: instruments.map(&:ticker))
      @prices_by_ticker = @prices.index_by &:ticker
    end

    def for_instrument(instrument) = @prices_by_ticker[instrument.ticker]
  end

  class DayCandleCache
    attr :candles, :candles_by_ticker

    def initialize(instruments, extra_dates)
      @instruments = instruments
      @candles = Candle.day.where(ticker: instruments.map(&:ticker), date: (SpecialDates.dates + extra_dates.to_a).uniq.sort).to_a
      @candles_by_ticker = @candles.group_by &:ticker
    end

    def scope_to_instrument(instrument) = InstrumentScope.new(instrument, self)

    class InstrumentScope
      attr :instrument

      def initialize(instrument, cache)
        @instrument, @cache = instrument, cache
      end

      def find_date(date)
        @cache.candles_by_ticker[@instrument.ticker]&.find { |candle| candle.date == date }
      end

      def find_date_before(date) = find_date(MarketCalendar.closest_weekday date)
    end
  end

  class SpecialDates
    include StaticService

    def dates
      [
        Date.parse('2019-01-03'),
        Date.parse('2020-01-03'),
        Date.parse('2020-02-19'),
        Date.parse('2020-03-23'),
        Date.parse('2020-11-06'),
        Date.parse('2021-01-04'),
        Current.date,
        Current.yesterday,
        Current.d2_ago,
        Current.d3_ago,
        Current.d4_ago,
        Current.d5_ago,
        Current.d6_ago,
        Current.d7_ago,
        Current.w2_ago,
        Current.month_ago,
      ]
    end

    def nyse_holidays
      %w[
        2021-01-01
        2021-01-18
        2021-02-15
        2021-04-02
        2021-05-31
        2021-07-05
        2021-09-06
        2021-12-24
      ].map { |str| Date.parse str }
    end
  end
end
