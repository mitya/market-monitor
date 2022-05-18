class WatchedTarget < ApplicationRecord
  # scope :today, -> { where 'created_at >= ?', Current.date - 1 }
  scope :today, -> { nil }
  scope :pending, -> { where hit_at: nil }
  scope :for, -> ticker { where ticker: ticker }

  before_create do
    self.start_price = instrument.last
  end

  def instrument = PermaCache.instrument(ticker)
  def bullish? = expected_price >= start_price
  def bearish? = expected_price <  start_price
  def hit? = hit_at?
  def swing? = keep?
  def intraday? = !keep?

  def check_hit_in(candle)
    hit! candle.time if hit_in? candle
  end

  def hit_in?(candle)
    bullish? ? candle.high >= expected_price : candle.low <= expected_price
  end

  def hit!(time = intstrument.calendar.time)
    return if hit?
    update hit_at: time
    notify
    create_hit_record
  end

  private

    def notify
      puts "Watch hit #{instrument} #{expected_price} at #{hit_at}".cyan

      action = bullish? ? 'rise to' : 'fall to'
      tg_message = "#{instrument} #{action} #{expected_price}"
      tg_message = "<i>#{tg_message}</i>" if bearish?
      tg_message = "<b>#{tg_message}</b>" if swing?
      TelegramGateway.push tg_message
    end

    def create_hit_record
      PriceLevelHit.create ticker: ticker, date: time.to_date, time: time&.to_s(:time),
        source: 'watch', manual: true, positive: bullish, level_value: expected_price
    end
end
