class InstrumentSet
  attr :key, :source, :params

  def initialize(key, source = :file, **params)
    @key = key&.to_sym
    @source = source
    @params = params || {}
  end

  def name = key ? key.to_s.humanize : 'All'

  def symbols
    @symbols ||= begin
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
  end

  def missing_symbols = symbols.select { |s| !Instrument.exists?(ticker: s) }
  def instruments = symbols.uniq.map { PermaCache.instrument _1 }.compact
  alias tickers symbols
  alias scope instruments

  def include?(ticker) = tickers.include?(ticker)

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

    def reload_categories!
      @categories = nil
    end

    def category_titles
      @category_titles ||= YAML.load_file("db/categories-titles.yaml")
    end

    def symbols_for_category(key)
      if key.to_s.end_with?('*')
        categories.values_at(*categories.keys.grep(Regexp.new key.to_s)).flatten
      else
        categories[key.to_s]
      end
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
    def n1 = @n1 ||= new(:'1')
    def n1?(symbol) = n1.include?(symbol)
    def watched?(symbol) = n1?(symbol)
  end
end

__END__

InstrumentSet.new(:main).symbols
InstrumentSet.symbols_for_category('shipping*')
