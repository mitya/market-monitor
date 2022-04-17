class TickerSet < ApplicationRecord
  def as_line = "#{key}  #{tickers_line}"
  def tickers_line = tickers.sort.join(' ').upcase

  class << self
    def moex_1 = Instrument.active.rub.where.not(ticker: MarketInfo::Moex2).pluck(:ticker).sort
    def moex_2 = Instrument.active.rub.where(    ticker: MarketInfo::Moex2).pluck(:ticker).sort

    def virtual
      %i[moex_1 moex_2].map { new(key: _1, tickers: send(_1)) }
    end

    def list
      order(:key) + virtual
    end

    def update_from_lines(lines)
      transaction do
        lines.each do |line|
          key, *tickers = line.split(' ')
          set = find_or_create_by(key: key)
          set.update! tickers: tickers.sort.map(&:upcase)
        end
      end
    end
  end
end
