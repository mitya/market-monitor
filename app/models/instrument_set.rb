class InstrumentSet
  attr :key

  def initialize(key)
    @key = key&.to_sym
  end

  def name = key ? key.to_s.humanize : 'All'

  def symbols
    @symbols ||= begin
      file = Pathname("db/instrument-sets/#{key}.txt")
      stored_symbols = file.exist?? file.readlines(chomp: true).map { |sym| sym.split(':').last.upcase } : []
      virtual_symbols = case key
        when :portfolio then PortfolioItem.pluck(:ticker)
        when :recommendations then PublicSignal.pluck(:ticker)
        when :alarms then PriceLevel.manual.distinct.pluck(:ticker)
        when :categorized then self.class.categories.values.flatten.sort
        else []
      end
      (stored_symbols + virtual_symbols).uniq.sort
    end
  end

  def missing_symbols = symbols.select { |s| !Instrument.exists?(ticker: s) }
  def instruments = Instrument.where(ticker: symbols)
  alias tickers symbols
  alias scope instruments

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
      @all ||= (Pathname.glob("db/instrument-sets/*.txt").map { |path| new path.basename('.txt').to_s } +
        %w[alarms recommendations categorized].map { |key| new key }).sort_by(&:key)
    end

    def all_with_null
      [null] + all
    end

    def categories
      @categories ||= YAML.load_file("db/categories.yaml").transform_values { |str| str.to_s.split.compact.map(&:upcase).uniq.sort }
    end

    def main = new(:main)
    def portfolio = @portfolio ||= new(:portfolio)
    def insiders = @insiders ||= new(:insiders)
    def recommendations = new(:recommendations)
    def alarms = @alarms ||= new(:alarms)
    def rejected = @rejected ||= new(:rejected)
    def categorized = @categorized ||= new(:categorized)
    def known_instruments = @known ||= [main, portfolio, recommendations].flat_map(&:instruments).uniq
    def known_symbols = @known_symbols ||= [main, portfolio, recommendations, categorized].flat_map(&:symbols).uniq
    def known?(symbol) = known_symbols.include?(symbol)
  end
end

__END__

InstrumentSet.new(:main).symbols
