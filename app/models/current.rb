class Current < ActiveSupport::CurrentAttributes
  attribute :day_candles_cache, :prices_cache

  def date
    date = Time.current.hour < 4 ? Date.yesterday : Date.current
    date.on_weekend?? date.prev_weekday : date
  end
  alias today date

  def ytd = date.beginning_of_year
  def est = Time.find_zone!('Eastern Time (US & Canada)')
  def msk = Time.find_zone!('Moscow')
  def ru_time = msk.now
  def us_time = est.now
  def us_date = us_time.to_date
  def us_market_open? = date.on_weekday? && us_time.to_s(:time) >= '09:30'
  def uk_market_open? = date.on_weekday? && Time.current.to_s(:time) >= '11:00'
  def ru_market_open_time = ru_time.change(hour: 7).utc
  def weekend? = us_date.on_weekend? || MarketCalendar.nyse_holidays.include?(us_date)
  def workday? = MarketCalendar.market_open?(Date.current)

  def us_market_open_time      = Current.us_time.change(hour:  9, min: 30)
  def us_market_close_time     = Current.us_time.change(hour: 16, min: 00)
  def ru_premarket_open_time   = Current.ru_time.change(hour: 7, min: 00)
  def ru_market_open_time      = Current.ru_time.change(hour: 10, min: 00)
  def ru_market_close_time     = Current.ru_time.change(hour: 22, min: 00)
  def ru_2nd_market_open_time  = Current.ru_time.change(hour: 10, min: 00)
  def ru_2nd_market_close_time = Current.ru_time.change(hour: 19, min: 30)
  def us_market_work_period     = us_market_open_time..us_market_close_time
  def ru_market_work_period     = ru_market_open_time..ru_market_close_time
  def ru_2nd_market_work_period = ru_2nd_market_open_time..ru_2nd_market_close_time


  def yesterday = weekend?? today : MarketCalendar.closest_weekday(date.prev_weekday)
  def d2_ago    = MarketCalendar.closest_weekday(yesterday.prev_weekday)
  def d3_ago    = MarketCalendar.closest_weekday(d2_ago.prev_weekday)
  def d4_ago    = MarketCalendar.closest_weekday(d3_ago.prev_weekday)
  def d5_ago    = MarketCalendar.closest_weekday(d4_ago.prev_weekday)
  def d6_ago    = MarketCalendar.closest_weekday(d5_ago.prev_weekday)
  def d7_ago    = MarketCalendar.closest_weekday(d6_ago.prev_weekday)
  def d10_ago   = MarketCalendar.closest_weekday(d7_ago.prev_weekday.prev_weekday.prev_weekday)
  def week_ago  = MarketCalendar.closest_weekday(1.week.ago.to_date)
  def month_ago = MarketCalendar.closest_weekday(1.month.ago.to_date)
  def y2017     = Date.new(2017,  1,  3)
  def y2018     = Date.new(2018,  1,  3)
  def y2019     = Date.new(2019,  1,  3)
  def y2020     = Date.new(2020,  1,  3)
  def y2021     = Date.new(2021,  1,  4)
  def feb19     = Date.new(2020,  2, 19)
  def mar23     = Date.new(2020,  3, 23)
  def nov06     = Date.new(2020, 11,  6)
  alias d0_ago today
  alias d1_ago yesterday
  alias w1_ago d5_ago
  alias w2_ago d10_ago
  alias m1_ago month_ago

  def us_open_time_in_minutes_utc = 13 * 60 + 30

  def last_closed_day = workday? ? yesterday : today
  # def last_closed_day_as_iex = workday? ? yesterday : yesterday - 1
  def last_closed_day_as_iex = yesterday

  def weekdays_since(date) = date.upto(Current.yesterday).to_a.select { |date| MarketCalendar.market_open?(date) }.reverse
  def last_n_weeks(n) = weekdays_since(n.weeks.ago.to_date)
  def last_2_weeks = last_n_weeks(2)

  def preload_day_candles_for(instruments)
    self.day_candles_cache = DayCandleCache.new(instruments, nil)
  end

  def preload_day_candles_with(instruments, extra_dates, dates: nil)
    self.day_candles_cache = DayCandleCache.new(instruments, extra_dates, dates: dates)
  end

  def preload_day_candles_for_dates(instruments, dates)
    self.day_candles_cache = DayCandleCache.new(instruments, [], dates: dates)
  end

  def preload_prices_for(instruments)
    self.prices_cache = PriceCache.new(instruments)
  end

  def in_usd(amount, currency)
    return unless amount
    case currency
    when 'USD' then amount
    when 'EUR' then amount * 1.2
    when 'RUB' then amount / 74
    end
  end

  def parallelize(threads_count, &block)
    threads_count.times.map { |i| Thread.new(&block) }.each &:join
  end

  def parallelize_instruments(instruments, threads_count, &block)
    # queue = Queue.new
    # instruments.each { |instr| queue << instr }
    queue = instruments.to_a
    threads_count.times.map do |index|
      Thread.new do
        while instr = queue.shift
          yield instr, index
        end
      end
    end.each &:join
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

    def initialize(instruments, extra_dates = nil, dates: nil)
      dates ||= (SpecialDates.dates + extra_dates.to_a)
      dates = dates.compact.uniq.sort
      @instruments = Instrument.normalize(instruments).compact unless instruments == :all
      @candles = Candle.day.where(date: dates)
      @candles = @candles.where(ticker: @instruments.map(&:ticker)) unless instruments == :all
      @candles = @candles.order(:date).to_a
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
      def find_date_or_after(date) = @cache.candles_by_ticker[@instrument.ticker]&.find { |candle| candle.date >= date }
      alias find_date_or_before find_date_before
      def find_dates_in(period) = @cache.candles_by_ticker[@instrument.ticker]&.select { |candle| candle.date.in? period }
    end
  end

  class SpecialDates
    include StaticService

    def dates
      [
        Current.y2017,
        Current.y2018,
        Current.y2019,
        Current.y2020,
        Current.y2021,
        Current.feb19,
        Current.mar23,
        Current.nov06,
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

    def dates_plus
      dates + []
    end
  end
end
