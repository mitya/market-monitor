class Candle < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  scope :ongoing, -> { where ongoing: true }
  scope :final, -> { where ongoing: false }
  scope :day, -> { where interval: 'day' }
  scope :todays, -> { where date: Current.date }
  scope :for_date, -> date { order(date: :desc).where(date: date.to_date) }
  scope :find_date, -> date { order(date: :desc).where(date: date.to_date).take }
  scope :find_date_before, -> date { order(date: :desc).where('date < ?', date.to_date).take }

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
  def previous = siblings.where(date: date.prev_weekday) || siblings.where('date < ?', date).order(:date).last

  class << self
    def last_loaded_date = final.maximum(:date)
  end
end
