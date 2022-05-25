class InstrumentSet
  attr :key, :source, :params

  def initialize(key, source = :file, **params)
    @key = key&.to_sym
    @source = source
    @params = params || {}
  end

  def name = key ? key.to_s.humanize : 'All'

  memoize def symbols
    case source
    when :category
      if Tops.respond_to?(key)
        Tops.send(key, **params)
      else
        self.class.symbols_for_category(key)
      end
    when :static
      params[:items].map(&:upcase)
    else
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
  def instruments = symbols.uniq.map { PermaCache.instrument _1 }.compact
  memoize def set = tickers.to_set
  alias tickers symbols
  alias scope instruments

  def include?(ticker) = set.include?(ticker)

  class << self
    def get(key)
      return key if self === key
      all.find { |set| set.key == key.to_sym }
    end

    alias [] get

    def null = new(nil)
    def all_with_null = [null] + all

    memoize def all
      (
        Pathname.glob("db/instrument-sets/*.txt").map { |path| new path.basename('.txt').to_s } +
        %w[alarms recommendations categorized].map { |key| new key }
      ).sort_by(&:key)
    end


    memoize def categories
      YAML.load_file("db/categories.yaml").transform_values { |str| str.to_s.split.compact.map(&:upcase).uniq.sort }
    end

    def reload_categories! = __unmemoize(:categories)

    memoize def category_titles = YAML.load_file("db/categories-titles.yaml")
    memoize def categories_per_ticker
      categories.each_with_object({}) do |(category, tickers), result|
        tickers.each do |ticker|
          result[ticker] = category
        end
      end
    end

    def symbols_for_category(key)
      if key.to_s.end_with?('*')
        categories.values_at(*categories.keys.grep(Regexp.new key.to_s)).flatten
      else
        categories[key.to_s]
      end
    end

    memoize def main = new(:main)
    memoize def portfolio = new(:portfolio)
    memoize def insiders = new(:insiders)
    memoize def recommendations = new(:recommendations)
    memoize def alarms = new(:alarms)
    memoize def rejected = new(:rejected)
    memoize def dead = new(:dead)
    memoize def categorized = new(:categorized)
    memoize def known_instruments = [main, portfolio, recommendations].flat_map(&:instruments).uniq
    memoize def known_symbols = [main, portfolio, recommendations, categorized].flat_map(&:symbols).uniq
    memoize def n1 = new(:'1')

    def known?(symbol) = known_symbols.include?(symbol)
    def n1?(symbol) = n1.include?(symbol)
    def watched?(symbol) = n1?(symbol)
    def dead?(symbol) = dead.include?(symbol)
  end
end

__END__

InstrumentSet.new(:main).symbols
InstrumentSet.symbols_for_category('shipping*')
