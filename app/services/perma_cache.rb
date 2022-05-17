class PermaCache
  include StaticService

  attr :instruments, :infos, :aggregates

  def initialize
  end


  def info(ticker)
    load_infos unless @infos
    @infos[ticker] ||= InstrumentInfo.create(ticker: ticker)
  end

  def instrument(ticker)
    load_instruments unless @instruments
    if @instruments[ticker] == nil
      puts "PermaCache miss instrument #{ticker} #{@instruments.size}"
    end
    @instruments[ticker]
  end

  def indicator(ticker)
    load_indicators unless @indicators
    @indicators[ticker]
  end

  def aggregate(ticker)
    load_aggregates unless @aggregates
    @aggregates[ticker]
  end


  def load_instruments
    ApplicationRecord.benchmark "Preload instruments".magenta, silence: true do
      @instruments ||= instruments_scope.index_by(&:ticker)
    end
  end

  def load_infos
    ApplicationRecord.benchmark "Preload infos".magenta, silence: true do
      @infos = InstrumentInfo.all.index_by(&:ticker)
    end
  end

  def load_aggregates
    ApplicationRecord.benchmark "Preload aggregates".magenta, silence: true do
      @aggregates = Aggregate.current.index_by(&:ticker)
    end
  end

  def load_indicators
    ApplicationRecord.benchmark "Preload indicators".magenta, silence: true do
      @indicators = DateIndicators.current.index_by(&:ticker)
    end
  end


  def instruments_for_market(market)
    @instruments_for_market ||= begin
      load_instruments unless @instruments
      active_instruments = @instruments.values.select { _1.active? && _1.type == 'Stock' }
      {
        ru: active_instruments.select { _1.currency == 'RUB' },
        us: active_instruments.select { _1.currency == 'USD' }
      }
    end
    @instruments_for_market[MarketCalendar.normalize_market market]
  end

  def current_instruments_for_market(market)
    @current_instruments_for_market ||= begin
      current_tickers = TickerSet.current
      {
        ru: instruments_for_market(market),
        us: instruments_for_market(market).select { current_tickers.include?(_1.ticker) }
      }
    end
    @current_instruments_for_market[MarketCalendar.normalize_market market]
  end

  def reset_current_instruments
    @current_instruments_for_market = nil
  end


  def instruments_scope = Instrument.active!

  class << self
    def instance = @instance ||= new
  end
end

__END__

PermaCache.info('AAPL')
