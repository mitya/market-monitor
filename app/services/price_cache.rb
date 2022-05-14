class PriceCache
  include StaticService

  def preload(instruments = [])
    return if @index
    ApplicationRecord.benchmark "Preload prices [#{instruments.size}]".magenta, silence: true do
      instruments = Instrument.normalize(instruments)
      prices = instruments.blank? || instruments.size > 30 ? Price.all : Price.where(ticker: instruments.pluck(:ticker))
      @index = prices.index_by &:ticker
    end
  end

  def for_instrument(instrument)
    preload
    @index[instrument.ticker]
  end

  class << self
    def instance = @instance ||= new
  end
end

__END__
