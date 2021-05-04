class Current < ActiveSupport::CurrentAttributes
  attribute :day_candles_cache, :prices_cache

  def date
    date = Time.current.hour < 5 ? Date.yesterday : Date.current
    date.on_weekend?? date.prev_weekday : date
  end
  alias today date

  def us_time = Time.find_zone!('Eastern Time (US & Canada)').now
  def us_date = us_time.to_date
  def us_market_open? = date.on_weekday? && us_time.to_s(:time) >= '09:30'
  def uk_market_open? = date.on_weekday? && Time.current.to_s(:time) >= '11:00'
  def weekend? = us_date.on_weekend? || MarketCalendar.nyse_holidays.include?(us_date)

  def yesterday = MarketCalendar.closest_weekday(date.prev_weekday)
  def d2_ago    = MarketCalendar.closest_weekday(yesterday.prev_weekday)
  def d3_ago    = MarketCalendar.closest_weekday(d2_ago.prev_weekday)
  def d4_ago    = MarketCalendar.closest_weekday(d3_ago.prev_weekday)
  def d5_ago    = MarketCalendar.closest_weekday(d4_ago.prev_weekday)
  def d6_ago    = MarketCalendar.closest_weekday(d5_ago.prev_weekday)
  def d7_ago    = MarketCalendar.closest_weekday(d6_ago.prev_weekday)
  def d10_ago   = MarketCalendar.closest_weekday(d7_ago.prev_weekday.prev_weekday.prev_weekday)
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

  def weekdays_since(date) = date.upto(Current.yesterday).to_a.select { |date| MarketCalendar.market_open?(date) }.reverse
  def last_n_weeks(n) = weekdays_since(n.weeks.ago.to_date)
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
    return unless amount
    case currency
    when 'USD' then amount
    when 'EUR' then amount * 1.2
    when 'RUB' then amount / 77
    end
  end

  class PriceCache
    def initialize(instruments)
      @instruments = Instrument.normalize(instruments)
      @prices = @instruments.size > 30 ? Price.all : Price.where(ticker: @instruments.map(&:ticker))
      @prices_by_ticker = @prices.index_by &:ticker
    end

    def for_instrument(instrument) = @prices_by_ticker[instrument.ticker]
  end

  class DayCandleCache
    attr :candles, :candles_by_ticker

    def initialize(instruments, extra_dates)
      @instruments = Instrument.normalize(instruments)
      @candles = Candle.day.where(ticker: @instruments.map(&:ticker), date: (SpecialDates.dates + extra_dates.to_a).uniq.sort).to_a
      @candles_by_ticker = @candles.group_by &:ticker
    end

    def scope_to_instrument(instrument) = InstrumentScope.new(instrument, self)

    class InstrumentScope
      attr :instrument

      def initialize(instrument, cache)
        @instrument, @cache = instrument, cache
      end

      def find_date(date) = @cache.candles_by_ticker[@instrument.ticker]&.find { |candle| candle.date == date }
      def find_date_before(date) = find_date(MarketCalendar.closest_weekday date)
      def find_dates_in(period) = @cache.candles_by_ticker[@instrument.ticker]&.select { |candle| candle.date.in? period }
    end
  end

  class SpecialDates
    include StaticService

    def dates
      [
        Current.y2019,
        Current.y2020,
        Current.feb19,
        Current.mar23,
        Current.nov06,
        Current.y2021,
        Current.date,
        Current.d1_ago,
        Current.d2_ago,
        Current.d3_ago,
        Current.d4_ago,
        Current.w1_ago,
        Current.w2_ago,
        Current.m1_ago,
      ]
    end
  end
end
