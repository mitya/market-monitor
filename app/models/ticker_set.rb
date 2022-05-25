class TickerSet < ApplicationRecord
  def as_line = "#{key}  #{tickers_line}"
  def tickers_line = tickers.sort.join(' ').upcase

  def include?(ticker)
    @items ||= tickers.to_set
    @items.include?(ticker)
  end

  def toggle_ticker(ticker)
    update tickers: tickers.include?(ticker) ? tickers.without(ticker) : tickers + [ticker]
    return tickers.include?(ticker)
  end

  def instruments = tickers.map { PermaCache.instrument _1 }

  def add(tickers)
    update tickers: (self.tickers | tickers).sort
  end

  def remove(ticker)
    update tickers: self.tickers.without(ticker)
  end

  class << self
    def cached = Current.ticker_sets ||= {}
    def get(key) = cached[key] ||= find_by(key: key)
    def favorites = get(:favorites)
    def current   = get(:current)

    def moex_1 = Instrument.active.rub.where.not(ticker: MarketInfo::Moex2).pluck(:ticker).sort
    def moex_2 = Instrument.active.rub.where(    ticker: MarketInfo::Moex2).pluck(:ticker).sort
    def watched = WatchedTarget.distinct.pluck(:ticker).sort
    %i[above_ma_20 above_ma_50 above_ma_200 below_ma_20 below_ma_50 below_ma_200].each { |method| define_method(method) { Tops.send(method) } }

    def virtual
      %i[moex_1 moex_2 watched above_ma_50 above_ma_200].map { new(key: _1, tickers: send(_1)) }
    end

    def stored = order(:key)
    def from_instrument_sets = InstrumentSet.all.map { new(key: _1.key, tickers: _1.symbols) }
    def list = order(:key) + virtual

    def update_from_lines(lines)
      transaction do
        lines.each do |line|
          key, *tickers = line.split(' ')
          set = find_or_create_by(key: key)
          set.update! tickers: tickers.sort.map(&:upcase)
        end
      end
    end

    def update_from_instrument_set(key)
      ticker_set = find_or_initialize_by key: key
      instrument_set = InstrumentSet[key]
      ticker_set.update tickers: instrument_set.tickers
    end
  end
end
