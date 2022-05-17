class WatchedTarget < ApplicationRecord
  scope :today, -> { where 'created_at >= ?', Current.date - 1 }
  scope :pending, -> { where hit_at: nil }
  scope :for, -> ticker { where ticker: ticker }

  def instrument = PermaCache.instrument(ticker)

  def bullish? = expected_price >= start_price
  def bearish? = expected_price <  start_price

  def hit_in?(candle)
    bullish? ? candle.high >= expected_price : candle.low <= expected_price
  end

  def hit!
    update hit_at: Time.current
  end

  before_create do
    self.start_price = instrument.last
  end
end
