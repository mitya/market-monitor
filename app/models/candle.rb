class Candle < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  scope :ongoing, -> { where ongoing: true }
  scope :final, -> { where ongoing: false }
  scope :day, -> { where interval: 'day' }
  scope :today, -> { where date: Current.date }
  scope :for_date, -> date { order(date: :desc).where(date: date.to_date) }
  scope :non_analyzed, -> { where analyzed: nil }
  scope :since, -> date { where 'date >= ?', date }
  scope :asc, -> { order :date }
  # scope :non_analyzed, -> { }

  scope :iex, -> { where source: 'iex' }
  scope :tinkoff, -> { where source: 'tinkoff' }

  def self.find_date_before(date)    = order(date: :desc).where('date <  ?', date.to_date).take
  def self.find_date_or_before(date) = order(date: :desc).where('date <= ?', date.to_date).take
  def self.find_date_or_after(date)  = order(date: :asc) .where('date >= ?', date.to_date).take
  def self.find_date(date)        = for_date(date).take
  def self.find_dates_in(period)  = where(date: period)

  def final? = !ongoing?

  def range = low..high
  def range_with_delta(delta = 0.02) = (low * (1 - delta)) .. (high * (1 + delta))
  def range_high = close > open ? close : open
  def range_low  = close < open ? close : open
  def top_shadow_spread = high - range_high
  def bottom_shadow_spread = range_low - low
  def shadows_spread = top_shadow_spread + bottom_shadow_spread
  def range_spread = range_high - range_low
  def spread = high - low
  def min = up?? low : high
  def max = up?? high : low
  alias body_low range_low
  alias body_high range_high

  def change = close - open
  def rel_change = (change / open).round(4)
  def close_change = close - previous&.close.to_d
  def rel_close_change = (close_change / open).round(4)

  def gap = open - previous&.close.to_d
  def gap? = gap > 0
  def rel_gap = gap?? gap / previous&.close.to_d : 0

  def diff_to(price, base_price = :close) = (send(base_price) - price) / price

  def close_time = date.in_time_zone(Current.est).change(hour: 16)

  def ohlc_row = [open, high, low, close]

  def range_spread_percent = range_spread.abs / close

  def close_min_rel = (close - min) / close
  def max_min_rel = (max - min) / max

  def range_s = "LH #{low}-#{high} OC #{open}-#{close}"

  def volatility_range = high - low
  def volatility = (high - low) / low
  def volatility_above = top_shadow_spread / range_high
  def volatility_below = bottom_shadow_spread / range_low
  def volatility_body  = (range_high - range_low) / range_low
  alias bottom_tail_range volatility_below
  alias top_tail_range volatility_above
  def larger_tail_range = volatility_above > volatility_below ? volatility_above : -volatility_below


  def up? = close >= open
  def down? = close < open
  def direction = up?? 'up' : 'down'
  def direction_rev = up?? 'down' : 'up'

  def trend_up? = previous && close >= previous.close
  def trend_down? = previous && close <= previous.close
  def days_up = trend_up? ? 1 + previous.days_up : 0
  def days_down = trend_down? ? 1 + previous.days_down : 0


  # def up_for?(period_count)
  #   prev_candles = n_previous(period_count)
  #   return unless prev_candles.size = period_count
  #   prev_candles.each_slice(2).take_while { |curr, prev| curr && prev && curr >= prev }.count if candle
  # end

  def body_to_shadow_ratio = range_spread / shadows_spread
  def shadow_to_body_ratio = shadows_spread / range_spread

  def siblings = instrument.candles.where(interval: interval)
  def previous = @previous ||= siblings.find_by(date: MarketCalendar.prev(date)) || siblings.where('date < ?', date).order(:date).last
  def previous_n(n) = siblings.where('date < ?', date).order(:date).last(n)
  def next = @next ||= siblings.find_by(date: MarketCalendar.next(date)) || siblings.where('date > ?', date).order(:date).first
  def after_n_days(n) = siblings.find_by(date: MarketCalendar.next(date + n)) || siblings.where('date > ?', date + n).order(:date).first

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
  def > (other) = close >  other.close # || high >= other.close
  def < (other) = close <  other.close # || low <= other.close

  def to_s = "<#{ticker}:#{interval}:#{date}>"

  def absorb?(other, tolerance_ratio = 0)
    return true if high >= other.high && low <= other.low

    tolerance = other.spread * tolerance_ratio
    return :almost if high >= other.high - tolerance && low <= other.low + tolerance
  end

  def overlaps?(other) = range.overlaps?(other.range)

  def pin_bar?(min_pin_height: 0.03)
    return if shadow_to_body_ratio <= 2
    yesterday = previous
    yesterday_aggregate = instrument.aggregates.find_by_date(yesterday.date)
    return if !yesterday_aggregate || !yesterday

    # printf "%8s %10.2f %i %i\n", ticker, shadow_to_body_ratio, yesterday_aggregate.days_up, yesterday_aggregate.days_down

    return 'down' if yesterday_aggregate.days_up   >= 2 && close < yesterday.close && high > yesterday.body_high && ((high - yesterday.close) / yesterday.close) > min_pin_height
    return 'up'   if yesterday_aggregate.days_down >= 2 && close > yesterday.close && low  < yesterday.body_low && ((yesterday.close - low ) / yesterday.close) > min_pin_height
  end

  def tail_bar?(prev)
    return if shadow_to_body_ratio <= 2.5
    return ['up', 1 - low  / prev.low] if low  < prev.low
    return ['down',  high / prev.high - 1] if high > prev.high
  end

  def interval_duration = self.class.interval_duration(interval)
  def abs_to_percent(value, base) = close * percent

  def average_prior_volume(days: 10) = siblings.where('date < ?', date).take(days).pluck(:volume).average
  def volume_change(days: 10) = volume.to_f / average_prior_volume(days: days)

  def volume_to_average = volume.to_f / instrument.info&.avg_volume rescue nil

  class << self
    def last_loaded_date = final.maximum(:date)

    def interval_class_for(interval)
      { 'hour' => H1, '5min' => M5, '1min' => M1, 'day' => self }[interval]
    end

    def interval_duration(interval)
      case interval
        when '5min' then 5.minutes
        when 'hour' then 1.hour
        when 'day'  then 1.day
      end
    end

    def remove_dups
      iex.find_each do |candle|
        exist = logger.silence do
          day.where.not(id: candle.id).where(ticker: candle.ticker, date: candle.date).exists?
        end
        if exist
          day.where.not(id: candle.id).where(ticker: candle.ticker, date: candle.date).delete_all
        end
      end
    end
  end

  class Intraday < Candle
    def siblings = self.class.where(instrument: instrument, interval: interval)
    def previous = siblings.find_by(time: time - interval_duration)
    def datetime = Time.parse("#{date} #{time} Z")
  end

  class H1 < Intraday
    self.table_name = "candles_h1"
  end

  class M5 < Intraday
    self.table_name = "candles_m5"
  end

  class M1 < Intraday
    self.table_name = "candles_m1"
  end

  class DayTinkoff < Candle
    self.table_name = "candles_d1_tinkoff"
  end
end
