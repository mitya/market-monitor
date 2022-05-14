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


  def load_instruments
    ApplicationRecord.benchmark "Preload instruments".magenta, silence: true do
      @instruments ||= instruments_scope.index_by(&:ticker)
    end
  end

  def load_infos
    ApplicationRecord.benchmark "Preload instrument infos".magenta, silence: true do
      @infos = Stats.where(ticker: instruments_scope).index_by(&:ticker)
    end
  end


  def instruments_scope = Instrument.active

  class << self
    def instance = @instance ||= new
  end
end

__END__

PermaCache.info('AAPL')
