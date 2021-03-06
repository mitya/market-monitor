class PriceSignal < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker', inverse_of: :signals
  has_one :result, class_name: 'PriceSignalResult', foreign_key: 'signal_id', dependent: :delete #, inverse_of: :signal
  belongs_to :m1_candle, foreign_key: :candle_id, class_name: 'Candle::M1', optional: true

  scope :yesterday, -> { where interval: 'day', date: Current.yesterday }
  scope :days, -> { where interval: 'day' }
  scope :h1, -> { where interval: 'hour' }
  scope :m5, -> { where interval: '5min' }
  scope :intraday, -> { where.not time: nil }
  scope :today, -> { where date: Current.date }
  scope :for_interval, -> interval { interval == 'intraday' ? intraday : where(interval: interval) }
  scope :outside_bars, -> { where kind: 'outside-bar' }
  scope :breakouts, -> { where kind: 'breakout' }
  scope :earnings_breakouts, -> { where kind: 'earnings-breakout' }
  scope :up, -> { where direction: 'up' }
  scope :down, -> { where direction: 'down' }
  scope :changed_more,              -> percent { where "(data->'change')::float > ?",              percent }
  scope :changed_next_day_more,     -> percent { where "(data->'next_day_change')::float > ?",     percent }
  scope :changed_from_10d_low_more, -> percent { where "(data->'change_from_10d_low')::float > ?", percent }
  scope :changed_from_5d_low_more,  -> percent { where "(data->'change_from_5d_low')::float > ?",  percent }

  def up? = direction == 'up'
  def stopped_out?(price = instrument.last) = price && stop && (up?? price < stop : price > stop)
  def can_enter?(price = instrument.last) = price && enter && (up?? price >= enter : price <= enter)
  alias in_money? can_enter?

  BreakoutFields = %w[next_1d_change next_1d_open next_1d_close prev_2w_high prev_1w_high prev_2w_low prev_1w_low] # change
  BreakoutFields.each do |field|
    define_method(field) { data&.dig(field) }
  end

  def safe_enter?(price = instrument.last, margin = 0.01) = price && (up?? enter - price >= enter * margin : price - enter >= enter * margin)

  def profit_ratio(current = instrument.last, use_stop: true)
    return if !current
    return -stop_size if use_stop && stopped_out?(current)
    ratio = (current - enter) / enter
    in_money?(current) ? ratio.abs : -ratio.abs
  end

  def candle
    if intraday?
      candle_id ?
        instrument.candles_for(interval).find(candle_id) :
        instrument.candles_for(interval).find_by( date: date, time: time)
    else
      instrument.day_candles!.find_date(date)
    end
  end

  def current = instrument.last
  def enter_to_current_ratio = (current && enter ? current / enter - 1.0 : 0)

  def tail_range = data&.dig('tail_range')
  def outside_range = data&.dig('outside_range')
  def vector = data&.dig('vector')
  def outside_bar? = kind == 'outside-bar'
  def volume_change_percent = volume_change && volume_change.to_f * 100
  def intraday? = interval != 'day'

  before_save do
    unless intraday?
      self.stop_size ||= ((enter - stop) / enter).abs.round(3) if enter && stop
      self.volume_change ||= candle&.volume_change&.round(1)
      self.on_level ||= instrument.levels.any? { |level| candle.range_with_delta(0.01).include?(level.value) }
    end
  end

  class << self
    concerning :Daily do
      def analyze_all(date: Current.yesterday, interval: 'day', force: true)
        where(date: date).destroy_all if force
        instruments = Instrument.active.abc
        PriceCache.preload instruments
        Current.parallelize_instruments(instruments, 6) { |inst| analyze inst, date, force: force }
      end

      def analyze(instrument, date, interval: 'day', force: true)
        instrument = Instrument[instrument]
        date = date.to_date
        return if !force && exists?(ticker: instrument.ticker, date: date)

        curr = today = instrument.candles.day.find_date(date)
        prev = yesterday = today&.previous
        return unless today && yesterday

        pt = curr.open / 100.0
        signal_attrs = { instrument: curr.instrument, date: curr.date, base_date: prev.date, interval: curr.interval }

        if match = (today.absorb?(yesterday, 0.0) && today.range_spread_percent > 0.01)
          puts "Detect on #{date} for #{instrument.ticker.ljust 8} outside-bar"
          create! instrument: instrument, date: today.date, base_date: yesterday.date, kind: 'outside-bar',
            accuracy: (today.spread / yesterday.spread).to_f.round(2),
            exact: match == true,
            direction: today.direction, enter: today.close, stop: today.min,
            stop_size: today.close_min_rel.abs.to_f.round(4)
        end

        if pin_vector = today.pin_bar?
          puts "Detect on #{date} for #{instrument.ticker.ljust 8} pin-bar"
          create! instrument: instrument, date: today.date, kind: 'pin-bar',
            direction: pin_vector, enter: pin_vector == 'up' ? today.high : today.low, stop: pin_vector == 'up' ? today.low : today.high,
            stop_size: today.max_min_rel.abs.to_f.round(4)
        end

        outside_range = prev.close - curr.low
        if curr.bottom_tail_range > 0.02 && outside_range > 4 * pt && curr.overlaps?(prev)
          puts "Detect on #{date} for #{instrument.ticker.ljust 8} spike-down"
          bullish = curr.close > prev.close || curr.up?
          create! signal_attrs.merge kind: 'spike-down',
            direction: bullish ? 'up' : 'down',
            enter: bullish ? curr.range_high : curr.range_low,
            data: {
              tail_range: curr.bottom_tail_range.to_f.round(2),
              outside_range: (outside_range / pt / 100.0).to_f.round(2),
              vector: 'down'
            }
        end

        outside_range = curr.high - prev.close
        if curr.top_tail_range > 0.02 && outside_range > 4 * pt && curr.overlaps?(prev)
          puts "Detect on #{date} for #{instrument.ticker.ljust 8} spike-up"
          bullish = curr.close > prev.close || curr.up?
          create! signal_attrs.merge kind: 'spike-up',
            direction: bullish ? 'up' : 'down',
            enter: bullish ? curr.range_high : curr.range_low,
            data: {
              tail_range: curr.top_tail_range.to_f.round(2),
              outside_range: (outside_range / pt / 100.0).to_f.round(2),
              vector: 'up'
            }
        end

        find_breakouts [instrument], dates: [date], direction: :up
        find_breakouts [instrument], dates: [date], direction: :down
      end

      def find_breakouts(instruments = Instrument.all, dates: Current.ytd..Current.date, direction: :up)
        max_move_in_prev_2w = 0.20
        min_change = 0.05

        Instrument.get_all(instruments).sort_by(&:ticker).each do |inst|
          dates.each do |date|
            candle = inst.day_candles.find_date(date)
            next if candle == nil
            next if candle.direction != direction.to_s
            next if candle.rel_change.abs < min_change

            last_10 = candle.previous_n(10)
            prev_2w_low  = last_10.min_by &:range_low
            prev_2w_high = last_10.max_by &:range_high

            next if already_moved_too_much = direction == :up ?
              (!prev_2w_low  || candle.diff_to(prev_2w_low.range_low, :open) > max_move_in_prev_2w) :
              (!prev_2w_high || candle.diff_to(prev_2w_high.range_high, :open) < -max_move_in_prev_2w)

            last_5 = last_10.sort_by(&:date).last(5)
            prev_1w_low  = last_5.min_by &:range_low
            prev_1w_high = last_5.max_by &:range_high
            next_day = candle.next
            spy_day = Instrument['SPY'].day_candles!.find_date(date)
            gap_change = candle.rel_gap if candle.gap?

            data = { }
            data[:change]         = candle.rel_change.to_f.round(3)
            data[:prev_2w_high]   = candle.diff_to(prev_2w_high.range_high, :open).round(3).to_f if prev_2w_high
            data[:prev_1w_high]   = candle.diff_to(prev_1w_high.range_high, :open).round(3).to_f if prev_1w_high
            data[:prev_2w_low]    = candle.diff_to(prev_2w_low.range_low,   :open).round(3).to_f if prev_2w_low
            data[:prev_1w_low]    = candle.diff_to(prev_1w_low.range_low,   :open).round(3).to_f if prev_1w_low
            data[:next_1d_change] = next_day.rel_change.round(3).to_f                            if next_day
            data[:next_1d_open]   = next_day.diff_to(candle.close, :open).round(3).to_f          if next_day
            data[:next_1d_close]  = next_day.diff_to(candle.close, :close).round(3).to_f         if next_day
            data[:spy_change]     = spy_day.rel_change.round(3).to_f                             if spy_day
            data[:gap]            = gap_change                                                   if gap_change

            signal = find_or_initialize_by kind: 'breakout', instrument: inst, date: date, direction: direction
            signal.update! enter: candle.close, stop: candle.open, data: data
            puts "Detect on #{date} for #{inst.ticker.ljust 8} breakout #{direction}"
          end
        end
      end

      def find_earnings_breakouts(instruments = Instrument.all, dates: Current.ytd..Current.date, direction: :up)
        min_full_change = 0.06

        Instrument.get_all(instruments).sort_by(&:ticker).each do |inst|
          inst.info.earning_dates.each do |earning_date|
            [0, 1, 2].each do |date_shift|
              date = MarketCalendar.next_closest_weekday(earning_date + date_shift)
              next if date > Current.yesterday

              candle = inst.day_candles.find_date(date)
              full_change = candle&.rel_close_change

              if full_change.to_f > min_full_change && candle.up?
                puts "Detect earnings breakout on #{date} (shift #{date_shift}) #{(full_change * 100).to_i.to_s.rjust 2}% for #{inst.ticker.ljust 8}"
                data = {
                  change: full_change.round(3),
                  gap: candle.rel_gap.to_f.round(3),
                  date_shift: date_shift
                }
                signal = find_or_initialize_by kind: 'earnings-breakout', instrument: inst, date: date, direction: direction
                signal.update! enter: candle.close, stop: candle.low, data: data
                break
              end
            end
          end
        end
      end
    end
  end
end


__END__

Candle::M5.update_all analyzed: nil
rake analyze date=2021-05-27
PriceSignal.analyze_intraday_history(%w[EQT], MarketCalendar.open_days(5.days.ago))
