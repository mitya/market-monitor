class PriceCache
  include StaticService

  def preload(instruments = [], auto: false)
    return if @index && auto
    ApplicationRecord.benchmark "Preload prices [#{instruments.size}]".magenta, silence: true do
      instruments = Instrument.normalize(instruments)
      prices = instruments.blank? || instruments.size > 30 ? Price.all : Price.where(ticker: instruments.pluck(:ticker))
      @index = prices.index_by &:ticker
    end
  end

  def for_instrument(ticker)
    preload [], auto: true
    @index[Instrument.normalize_ticker ticker]
  end

  alias [] for_instrument

  class << self
    def instance = @instance ||= new
  end
end

__END__
