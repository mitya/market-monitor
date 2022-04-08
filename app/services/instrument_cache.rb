class InstrumentCache
  include StaticService

  def initialize
    @cache ||= {}
  end

  def set(instruments)
    instruments.each { |instrument| @cache[instrument.ticker] = instrument }
  end

  def get(ticker)
    @cache[ticker.to_s] ||= Instrument.find_by(ticker: ticker)
  end

  def count
    @cache.count
  end

  class << self
    def instance
      @instance ||= new
    end
  end
end
