class PermaCache
  include StaticService

  def initialize
  end


  def info(ticker)
    load_infos unless @infos
    @infos[ticker] ||= Stats.create(ticker: ticker)
  end

  def instrument(ticker)
    load_instruments unless @instruments
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
      @infos = Stats.all.index_by(&:ticker)
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


  # def intraday_instruments_for_market(market)
  #   load_instruments unless @instruments
  #   @intraday_instruments_for_market[market] ||
  # end


  def instruments_scope = Instrument.active

  class << self
    def instance = @instance ||= new
  end
end

__END__

PermaCache.info('AAPL')
