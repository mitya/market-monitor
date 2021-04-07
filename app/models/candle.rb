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

  def volatility_range = high - low
  def volatility = (high - low) / low
  def volatility_above = (high - range_high) / high
  def volatility_below = (range_low - low) / range_low
  def volatility_body  = (range_high - range_low) / range_low

  def up? = close >= open
  def down? = close < open
  def direction = up?? 'up' : 'down'

  def siblings = instrument.candles.where(interval: interval)
  def previous = siblings.find_by(date: MarketCalendar.prev(date)) || siblings.where('date < ?', date).order(:date).last
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

  class << self
    def last_loaded_date = final.maximum(:date)
  end
end
