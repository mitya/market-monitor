class WatchedTarget < ApplicationRecord
  scope :today, -> { nil }
  scope :pending, -> { where hit_at: nil }
  scope :for, -> ticker { where ticker: ticker }

  before_create { self.start_price = instrument.last }

  def instrument = PermaCache.instrument(ticker)
  def bullish? = target_price >= start_price
  def bearish? = target_price <  start_price
  def hit? = hit_at?
  def swing? = keep?
  def intraday? = !keep?
  def ma? = expected_ma.present?
  def price? = expected_price.present?

  memoize def ma_price = expected_ma && instrument.indicators.ma_value_for(expected_ma)
  memoize def target_price = price?? expected_price : ma_price

  def check_hit_in(candle)
    hit! candle.datetime if hit_in? candle
  end

  def hit_in?(candle)
    bullish? ? candle.high >= target_price : candle.low <= target_price
  end

  def hit!(time = intstrument.calendar.time)
    return if hit?
    update hit_at: time
    notify
    create_hit_record
  end

  private

    def notify
      action_text = bullish? ? 'rise to' : 'fall to'
      ma_text = "— MA#{expected_ma}" if expected_ma
      message = "#{instrument} #{action_text} #{target_price} #{ma_text}".squish

      puts "Watch hit: #{message}".cyan
      tg_message = "<i>#{   message}</i>" if bearish?
      tg_message = "<b>#{tg_message}</b>" if swing?
      TelegramGateway.push tg_message
    end

    def create_hit_record
      PriceLevelHit.create ticker: ticker, date: hit_at.to_date, time: hit_at, kind: 'watch'
        source: price?? 'level' : 'ma', manual: true, positive: bullish?, level_value: expected_price, ma_length: expected_ma
    end
end
