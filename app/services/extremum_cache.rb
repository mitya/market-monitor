class ExtremumCache
  include StaticService

  def initialize
    @cache ||= {}
  end

  def preload(date)
    @cache[date] ||= begin
      Candle.connection.select_rows("
        select ticker, min(low), max(high) from candles where date >= '#{date}' and
        ticker in (select ticker from instruments where currency = 'RUB') group by ticker order by ticker
      ".squish).index_by(&:first)
    end
  end

  def get(ticker, date, direction)
    preload date
    index = direction == :low ? 1 :2
    @cache.dig date, ticker, index
  end

  class << self
    def instance = @instance ||= new
  end
end

__END__
ExtremumCache.get('TCSG', '2022-04-01'.to_date, :high)
