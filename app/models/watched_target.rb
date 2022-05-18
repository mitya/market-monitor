class WatchedTarget < ApplicationRecord
  # scope :today, -> { where 'created_at >= ?', Current.date - 1 }
  scope :today, -> { nil }
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
    notify
  end

  def notify
    puts "Watch hit #{instrument} #{expected_price} at #{hit_at}".cyan
    TelegramGateway.push "#{instrument} hit #{expected_price}"
  end

  before_create do
    self.start_price = instrument.last
  end
end
