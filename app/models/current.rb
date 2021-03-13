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
      @prices = InstrumentPrice.where(figi: instruments.map(&:isin))
      @prices_by_isin = @prices.index_by &:figi
    end

    def for_instrument(instrument) = @prices_by_isin[instrument.isin]
  end

  class DayCandleCache
    attr :candles, :candles_by_isin

    def initialize(instruments)
      @instruments = instruments
      @candles = Candle.day.where(isin: instruments.map(&:isin), date: SpecialDates.dates).to_a
      @candles_by_isin = @candles.group_by &:isin
    end

    def scope_to_instrument(instrument) = InstrumentScope.new(instrument, self)

    class InstrumentScope
      attr :instrument

      def initialize(instrument, cache)
        @instrument, @cache = instrument, cache
      end

      def find_date(date)
        @cache.candles_by_isin[@instrument.isin]&.find { |candle| candle.date == date }
      end

      def find_date_before(date) = find_date(date)
    end
  end

  class SpecialDates
    include StaticService

    def dates
      [
        Date.parse('2020-02-19'),
        Date.parse('2020-03-23'),
        Date.parse('2020-11-06'),
        Date.parse('2021-01-04'),
        self_or_previous_workday(1.week.ago.to_date),
        self_or_previous_workday(1.month.ago.to_date),
        Current.today,
        Current.yesterday,
      ]
    end

    def self_or_previous_workday(date)
      date.wday == 0 ? date - 2 :
      date.wday == 6 ? date - 1 :
      date
    end
  end
end
