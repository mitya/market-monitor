class PriceSignal < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  def up? = direction == 'up'
  def stopped_out?(price = instrument.last) = price && stop && (up?? price <= stop : price >= stop)
  def can_enter?(price = instrument.last) = price && enter && (up?? price >= enter : price <= enter)
  alias in_money? can_enter?

  def profit_ratio(current = instrument.last)
    return if !current
    return -stop_size if stopped_out?
    ratio = (current - enter) / enter
    in_money? ? ratio.abs : -ratio.abs
  end

  def candle = instrument.day_candles!.find_date(date)

  class << self
    def analyze_all(date: Current.yesterday)
      instruments = Instrument.all.abc
      Current.preload_prices_for instruments

      where(date: Current.yesterday).delete_all
      instruments.each { |instrument| analyze instrument, date }
    end

    def analyze(instrument, date)
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
  end
end
