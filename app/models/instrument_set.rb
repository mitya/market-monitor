class InstrumentSet
  attr :key

  def initialize(key)
    @key = key&.to_sym
  end

  def name = key ? key.to_s.humanize : 'All'
  def symbols = @symbols ||= Pathname("db/instrument-sets/#{key}.txt").readlines(chomp: true).map { |sym| sym.split(':').last }
  def missing_symbols = symbols.select { |s| !Instrument.exists?(ticker: s) }
  def instruments = Instrument.where(ticker: symbols)
  alias tickers symbols

  class << self
    def get(key)
      return key if self === key
      all.find { |set| set.key == key.to_sym }
    end

    alias [] get

    def null
      new(nil)
    end

    def all
      @all ||= Pathname.glob("db/instrument-sets/*.txt").map { |path| new path.basename('.txt').to_s }
    end

    def all_with_null
      [null] + all
    end

    def main = new(:main)
    def portfolio = new(:portfolio)
  end
end

__END__

InstrumentSet.new(:main).symbols
