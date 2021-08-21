class Extremum < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  HISTORY_START = Date.parse('2020-01-01')
  PERIOD = 10

  class << self
    def create_all(period: PERIOD, instruments: Instrument.all.abc)
      instruments.each { |instrument| create_for instrument, period: period }
    end

    def create_for(instrument, period: PERIOD)
      instrument = Instrument[instrument]
      candles = instrument.candles.day.where(date: HISTORY_START..Current.date).order(:date)
      inner_candles = candles[period .. -period]
      return if inner_candles == nil

      %w[low high].map do |selector|
        operator = selector == 'low' ? :>= : :<=
        inner_candles.select.with_index do |current, index|
          if candles[index, period * 2].without(current).all? { |other| other.send(selector).send(operator, current.send(selector)) }
            create! ticker: instrument.ticker, date: current.date, kind: selector, value: current.send(selector), close: current.close, period: period
          end
        end
      end

      extremums = instrument.extremums.order(:date)
      extremums.each_with_index do |extremum, index|
        next if index == 0
        previous = extremums[0 ... index].reverse
        last_min = previous.find { |other| other.kind == 'low' }
        last_max = previous.find { |other| other.kind == 'high' }
        extremum.update! last_low_in:  extremum.date - last_min.date if last_min
        extremum.update! last_high_in: extremum.date - last_max.date if last_max
      end
    end
  end
end

__END__

Extremum.delete_all
Extremum.create_for 'DK'
instrument = instr('DK')
