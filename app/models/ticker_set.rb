class TickerSet < ApplicationRecord
  def as_line = "#{key}  #{tickers_line}"
  def tickers_line = tickers.sort.join(' ').upcase
  
  class << self
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
