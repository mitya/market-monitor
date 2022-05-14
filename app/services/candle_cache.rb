class CandleCache
  include StaticService
  attr :candles, :candles_by_ticker

  def initialize
    @loaded_dates = Set.new
  end

  def preload(instruments = nil, *args, dates: nil)
    return if @index && (dates == nil || dates.all? { @loaded_dates.include? _1 })

    dates = dates.to_a + MarketCalendar::SpecialDates.dates
    dates = dates.reject { @loaded_dates.include? _1 }
    dates = dates.compact.uniq.sort

    ApplicationRecord.benchmark "Preload candles [#{dates.size} dates]".magenta, silence: true do
      candles = Candle.day.where(date: dates).order(:date).to_a
      candles_by_ticker = candles.group_by &:ticker
      @loaded_dates.merge dates
      if @index
        candles_by_ticker.each do |ticker, new_candles|
          @index[ticker] ||= []
          @index[ticker] += new_candles
          @index[ticker] = @index[ticker].sort_by(&:date)
        end
      else
        @index = candles_by_ticker
      end
    end
  end


  def find_date(ticker, date)          = @index[ticker]&.find { _1.date == date }
  def find_date_or_before(ticker, date)= @index[ticker]&.reverse_each&.find { _1.date <= date }
  def find_date_or_after(ticker, date) = @index[ticker]&.find { _1.date >= date }
  def find_dates_in(ticker, period)    = @index[ticker]&.select { _1.date.in? period }

  def for_instrument(instrument) = InstrumentScope.new(instrument, self)


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
    def find_dates_in(period)    = @cache.find_dates_in(ticker, date)
  end
end

__END__
