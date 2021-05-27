class PriceSignal < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  scope :days, -> { where interval: 'day' }
  scope :h1, -> { where interval: 'hour' }
  scope :m5, -> { where interval: '5min' }
  scope :intraday, -> { where interval: %w[5min hour] }
  scope :for_interval, -> interval { interval == 'intraday' ? intraday : where(interval: interval) }

  def up? = direction == 'up'
  def stopped_out?(price = instrument.last) = price && stop && (up?? price <= stop : price >= stop)
  def can_enter?(price = instrument.last) = price && enter && (up?? price >= enter : price <= enter)
  alias in_money? can_enter?

  def profit_ratio(current = instrument.last, use_stop: true)
    return if !current
    return -stop_size if stopped_out? && use_stop
    ratio = (current - enter) / enter
    in_money? ? ratio.abs : -ratio.abs
  end

  def candle = instrument.day_candles!.find_date(date)

  def current = instrument.last
  def enter_to_current_ratio = (current && enter ? current / enter - 1.0 : 0)

  class << self
    def analyze_all(date: Current.yesterday, interval: 'day')
      instruments = Instrument.all.abc
      Current.preload_prices_for instruments

      where(date: date).delete_all
      instruments.each { |instrument| analyze instrument, date }
    end

    def analyze(instrument, date, interval: 'day')
      instrument = Instrument[instrument]
      date = date.to_date

      today = instrument.candles.day.find_date(date)
      yesterday = today&.previous
      return unless today && yesterday

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

      # spike
    end
  end
end


__END__

Candle::H1.update_all analyzed: nil
Candle::M5.update_all analyzed: nil
