class Instrument < ApplicationRecord
  self.inheritance_column = nil
  has_many :candles, foreign_key: 'isin'

  scope :tinkoff, -> { where "'tinkoff' = any(flags)" }
  scope :abc, -> { order :ticker }

  def to_s = ticker
  def current = 1234

  def open
    # Candle.get(self, Date.today, :open)
  end

  def close
  end

  def open_p
  end

  class << self
    def get(ticker = nil, figi: nil)
      figi ? find_by_figi(figi) : find_by_ticker(ticker.to_s.upcase)
    end
  end
end

# Instrument.where(flags: ['ti'])
