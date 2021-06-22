class PriceSignal < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  scope :yesterday, -> { where interval: 'day', date: Current.yesterday }
  scope :days, -> { where interval: 'day' }
  scope :h1, -> { where interval: 'hour' }
  scope :m5, -> { where interval: '5min' }
  scope :intraday, -> { where interval: %w[5min hour] }
  scope :for_interval, -> interval { interval == 'intraday' ? intraday : where(interval: interval) }
  scope :outside_bars, -> { where kind: 'outside-bar' }
  scope :up, -> { where direction: 'up' }
  scope :down, -> { where direction: 'down' }

  def up? = direction == 'up'
  def stopped_out?(price = instrument.last) = price && stop && (up?? price <= stop : price >= stop)
  def can_enter?(price = instrument.last) = price && enter && (up?? price >= enter : price <= enter)
  alias in_money? can_enter?

  def safe_enter?(price = instrument.last, margin = 0.01) = price && (up?? enter - price >= enter * margin : price - enter >= enter * margin)

  def profit_ratio(current = instrument.last, use_stop: true)
    return if !current
    return -stop_size if stopped_out? && use_stop
    ratio = (current - enter) / enter
    in_money? ? ratio.abs : -ratio.abs
  end

  def candle = instrument.day_candles!.find_date(date)

  def current = instrument.last
  def enter_to_current_ratio = (current && enter ? current / enter - 1.0 : 0)

  def tail_range = data&.dig('tail_range')
  def outside_range = data&.dig('outside_range')
  def vector = data&.dig('vector')

  def outside_bar? = kind == 'outside-bar'

  class << self
    def analyze_all(date: Current.yesterday, interval: 'day')
      where(date: date).delete_all
      instruments = Instrument.all.abc
      Current.preload_prices_for instruments
      Current.parallelize_instruments(instruments, 6) { |inst| analyze inst, date }
      # instruments.each { |instrument| analyze instrument, date }
    end

    def analyze(instrument, date, interval: 'day')
      instrument = Instrument[instrument]
      date = date.to_date

      curr = today = instrument.candles.day.find_date(date)
      prev = yesterday = today&.previous
      return unless today && yesterday

      pt = curr.open / 100.0
      signal_attrs = { instrument: curr.instrument, date: curr.date, base_date: prev.date, interval: curr.interval }

      if match = (today.absorb?(yesterday, 0.0) && today.range_spread_percent > 0.01)
        puts "Detect outside-bar on #{date} for #{instrument}"
        create! instrument: instrument, date: today.date, base_date: yesterday.date, kind: 'outside-bar',
          accuracy: (today.spread / yesterday.spread).to_f.round(2),
          exact: match == true,
          direction: today.direction, enter: today.close, stop: today.min,
          stop_size: today.close_min_rel.abs.to_f.round(4)
      end

      if pin_vector = today.pin_bar?
        puts "Detect pin-bar on #{date} for #{instrument}"
        create! instrument: instrument, date: today.date, kind: 'pin-bar',
          direction: pin_vector, enter: pin_vector == 'up' ? today.high : today.low, stop: pin_vector == 'up' ? today.low : today.high,
          stop_size: today.max_min_rel.abs.to_f.round(4)
      end

      outside_range = prev.close - curr.low
      if curr.bottom_tail_range > 0.02 && outside_range > 4 * pt && curr.overlaps?(prev)
        puts "Detect spike-down on #{curr.date} for #{curr.instrument}"
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
        puts "Detect spike-up on #{curr.date} for #{curr.instrument}"
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
    end

    def analyze_intraday(candle)
      curr = candle
      prev = candle&.previous

      curr.update! analyzed: true
      return unless curr && prev

      signal_attrs = { instrument: curr.instrument, date: curr.date, base_date: curr.date, time: curr.time, interval: candle.interval }

      if match = (curr.absorb?(prev, 0.0) && curr.range_spread_percent > 0.015)
        puts "Detect at #{curr.time.in_time_zone Current.msk} outside-bar for #{curr.instrument}"
        create! signal_attrs.merge kind: 'outside-bar',
          accuracy: (curr.spread / prev.spread).to_f.round(2),
          exact: match == true,
          direction: curr.direction, enter: curr.close, stop: curr.min,
          stop_size: curr.close_min_rel.abs.to_f.round(4)
      end

      pin_vector, ratio = curr.tail_bar?(prev)
      if pin_vector && ratio > 0.015
        puts "Detect at #{curr.time.in_time_zone Current.msk} tail-bar for #{curr.instrument} #{pin_vector} #{ratio&.round(4)}"
        create! signal_attrs.merge kind: 'tail-bar',
          direction: pin_vector,
          enter: pin_vector == 'up' ? curr.high : curr.low,
          stop: pin_vector == 'up' ? curr.low : curr.high,
          stop_size: curr.max_min_rel.abs.to_f.round(4),
          accuracy: ratio.to_f.round(4)
      end
    end
  end
end


__END__

Candle::H1.update_all analyzed: nil
Candle::M5.update_all analyzed: nil
rake analyze
rake analyze date=2021-05-27
