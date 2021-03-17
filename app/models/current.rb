class Current < ActiveSupport::CurrentAttributes
  attribute :day_candles_cache, :prices_cache

  def date
    date = Time.current.hour < 7 ? Date.yesterday : Date.current
    date.on_weekend?? date.prev_weekday : date
  end
  alias today date

  def yesterday
    date.prev_weekday
  end

  def preload_day_candles_for(instruments)
    self.day_candles_cache = DayCandleCache.new(instruments)
  end

  def preload_prices_for(instruments)
    self.prices_cache = PriceCache.new(instruments)
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

    def initialize(instruments)
      @instruments = instruments
      @candles = Candle.day.where(ticker: instruments.map(&:ticker), date: SpecialDates.dates).to_a
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

      def find_date_before(date) = find_date(MarketCalendar.closest_workday date)
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
        MarketCalendar.closest_workday(1.week.ago.to_date),
        MarketCalendar.closest_workday(1.month.ago.to_date),
        Current.today,
        Current.yesterday,
        Current.yesterday.yesterday,
      ]
    end
  end
end
