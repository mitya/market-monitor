class PriceLevel < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  HISTORY_START = Date.parse('2020-01-01')
  ACCURACY = 0.02
  PERIOD = 10

  class Extremum
    attr :candle, :selector

    def initialize(candle, selector) = (@candle, @selector = candle, selector)
    def high? = @selector == 'high'
    def low? = @selector == 'low'
    def value = @candle.send(@selector)
    def date = @candle.date
  end

  class << self
    def search_all
      Instrument.all.abc.each { |inst| search inst }
      nil
    end

    def search(instrument)
      candles = instrument.candles.day.where(date: HISTORY_START..Date.current).order(:date)
      inner_candles = candles[PERIOD..-PERIOD]
      return if not inner_candles

      lows, highs = %w[low high].map do |selector|
        operator = selector == 'low' ? :>= : :<=
        extremums = inner_candles.select.with_index do |current, index|
          is_extremum = candles[index, PERIOD * 2].without(current).all? { |other| other.send(selector).send(operator, current.send(selector)) }
        end
        extremums.map { |candle| Extremum.new(candle, selector) }
      end

      extremums = highs + lows

      groups = []
      extremums.each do |extremum|
        if group = groups.detect { |group| group.any? { |other| Math.in_delta?(extremum.value, other.value, ACCURACY) } }
          group << extremum
        else
          groups << [extremum]
        end
      end

      groups.each do |extremums|
        average = extremums.map(&:value).sum / extremums.count
        value = average.round(1)
        find_or_create_by!(ticker: instrument.ticker, value: value) do |level|
          level.dates = extremums.map(&:date)
          level.accuracy = ACCURACY
          level.period = PERIOD

          is_low  = extremums.any?(&:low?)
          is_high = extremums.any?(&:high?)
          level.kind = is_low && is_high ? 'multi' : is_low ? 'low' : 'high'
        end
      end

      nil
    end
  end
end

__END__

PriceLevel.search instr('DOCU')
PriceLevel.search_all

instr('DOCU').candles.day.where(date: Date.parse('2021-06-05')..Date.current).count
