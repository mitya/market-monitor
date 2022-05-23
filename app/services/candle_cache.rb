class CandleCache
  include StaticService
  attr :candles, :candles_by_ticker

  def initialize
    @loaded_dates = Set.new
  end

  def preload!(instruments = nil, *args, dates: nil)
    if loaded?(dates)
      reload_today instruments
    else
      preload instruments, *args, dates: dates
    end
  end

  def loaded?(dates)
    @index && (dates == nil || dates.all? { @loaded_dates.include? _1 })
  end

  def preload(instruments = nil, *args, dates: nil)
    return if loaded?(dates)

    dates = dates.to_a + MarketCalendar::SpecialDates.dates
    dates = dates.reject { @loaded_dates.include? _1 }
    dates = dates.compact.uniq.sort

    ApplicationRecord.benchmark "Preload candles [#{dates.size} dates]".magenta, silence: true do
      update_index Candle.day.where(date: dates)
      @loaded_dates.merge dates

      # candles_by_ticker = candles.group_by &:ticker
      # if @index
      #   candles_by_ticker.each do |ticker, new_candles|
      #     # @index[ticker] ||= []
      #     # @index[ticker] += new_candles
      #     # @index[ticker] = @index[ticker].sort_by(&:date)
      #   end
      # else
      #   @index = candles_by_ticker
      # end
    end
  end


  def find_date(ticker, date) = @index.dig(ticker, date)

  def find_date_or_before(ticker, date)
    if dates = @index[ticker]&.keys
      if date = dates.sort.reverse_each&.find { _1.date <= date }
        @index[ticker][date]
      end
    end
  end

  def find_date_or_after(ticker, date)
    if dates = @index[ticker]&.keys
      if date = dates.sort.find { _1.date >= date }
        @index[ticker][date]
      end
    end
  end

  def find_dates_in(ticker, period)
    if @index[ticker]
      @index[ticker].select { |date, candle| date.in? period }
    end
  end

  # def find_date(ticker, date)          = @index[ticker]&.find { _1.date == date }
  # def find_date_or_before(ticker, date)= @index[ticker]&.reverse_each&.find { _1.date <= date }
  # def find_date_or_after(ticker, date) = @index[ticker]&.find { _1.date >= date }
  # def find_dates_in(ticker, period)    = @index[ticker]&.select { _1.date.in? period }

  def for_instrument(instrument) = InstrumentScope.new(instrument, self)

  def update(candle)
    update_index [candle]
    # @index[candle.ticker] ||= []
    # @index[candle.ticker].delete_if { _1.date == candle.date }
    # @index[candle.ticker].push candle
    # @index[candle.ticker].sort_by! &:date
  end

  def reload_today(instruments = nil)
    ApplicationRecord.benchmark "Reload today for #{instruments&.size} instruments".magenta, silence: true do
      update_index Candle.day.where(date: Current.date, ticker: instruments)
    end
  end

  private

    def update_index(candles)
      @index ||= {}
      candles.each do |candle|
        @index[candle.ticker] ||= {}
        @index[candle.ticker][candle.date] = candle
      end
    end


  class << self
    def instance = @instance ||= new
  end


  class InstrumentScope
    attr :instrument, :ticker

    def initialize(instrument, cache)
      @instrument, @cache = instrument, cache
      @ticker = @instrument.ticker
      @cache.preload
    end

    def find_date(date)          = @cache.find_date(ticker, date)
    def find_date_or_before(date)= @cache.find_date_or_before(ticker, date)
    def find_date_or_after(date) = @cache.find_date_or_after(ticker, date)
    def find_dates_in(period)    = @cache.find_dates_in(ticker, period)
  end
end

__END__
