class Candle < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  scope :ongoing, -> { where ongoing: true }
  scope :final, -> { where ongoing: false }
  scope :day, -> { where interval: 'day' }
  scope :today, -> { where date: Current.date }
  scope :for_date, -> date { order(date: :desc).where(date: date.to_date) }

  def self.find_date_before(date) = order(date: :desc).where('date < ?', date.to_date).take
  def self.find_date(date)        = for_date(date).take
  def self.find_dates_in(period)  = where(date: period)

  def final? = !ongoing?

  def range_high = close > open ? close : open
  def range_low  = close < open ? close : open
  def top_shadow_spread = high - range_high
  def bottom_shadow_spread = range_low - low
  def range_spread = range_high - range_low
  def spread = high - low


  def volatility_range = high - low
  def volatility = (high - low) / low
  def volatility_above = (high - range_high) / high
  def volatility_below = (range_low - low) / range_low
  def volatility_body  = (range_high - range_low) / range_low

  def up? = close >= open
  def down? = close < open
  def direction = up?? 'up' : 'down'

  # def up_for?(period_count)
  #   prev_candles = n_previous(period_count)
  #   return unless prev_candles.size = period_count
  #   prev_candles.each_slice(2).take_while { |curr, prev| curr && prev && curr >= prev }.count if candle
  # end

  def body_to_shadow_ratio = range_spread / (top_shadow_spread + bottom_shadow_spread)

  def siblings = instrument.candles.where(interval: interval)
  def previous = siblings.find_by(date: MarketCalendar.prev(date)) || siblings.where('date < ?', date).order(:date).last
  def n_previous(n) = each_previous(with_self: false).take(n)
  def each_previous(with_self: true)
    curr = self
    Enumerator.new do |yielder|
      yielder << curr if with_self
      yielder << curr while curr = curr.previous
    end
  end

  def >=(other) = close >= other.close # || high >= other.close
  def <=(other) = close <= other.close # || low <= other.close

  def to_s = "<#{ticker}:#{interval}:#{date}>"

  def absorb?(other, tolerance_ratio = 0)
    return true if high >= other.high && low <= other.low

    tolerance = other.spread * tolerance_ratio
    return :almost if high >= other.high - tolerance && low <= other.low + tolerance
  end

  def pin_bar?(min_pin_height: 0.03)
    return if body_to_shadow_ratio < 2
    yesterday_aggregate = instrument.aggregates.find_by_date(MarketCalendar.prev date)
    return if yesterday_aggregate == nil

    return :top    if yesterday_aggregate.days_up   > 2 && close < yesterday.close && top > yesterday.close && ((top - yesterday.close) / yesterday.close) > min_pin_height
    return :bottow if yesterday_aggregate.days_down > 2 && close > yesterday.close && bottom < yesterday.close && ((yesterday.close - bottom) / yesterday.close) > min_pin_height
  end

  class << self
    def last_loaded_date = final.maximum(:date)
  end
end
