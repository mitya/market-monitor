class PriceLevel < ApplicationRecord
  belongs_to :instrument, foreign_key: 'ticker'

  HISTORY_START = Date.parse('2020-01-01')

  class << self
    def search_all
      Instrument.all.abc.each { |inst| search inst }
      nil
    end

    def search(instrument)
      side_gap = 10
      candles = instrument.candles.day.where(date: HISTORY_START..Date.current).order(:date)
      inner_candles = candles[side_gap..-side_gap]
      return if not inner_candles

      lowests = inner_candles.select.with_index do |current, index|
        index = index + side_gap
        is_lowest = candles[index - 10, 20].without(current).all? { |other| other.low >= current.low }
      end

      # lowests.each { |cndl| puts "#{cndl.date} - #{cndl.low}" }

      groups = []
      lowests.each do |candle|
        if existing_group = groups.detect { |group| group.any? { |other| (candle.low - other.low).abs < candle.low * 0.02 } }
          existing_group << candle
        else
          groups << [candle]
        end
      end

      # levels =  groups.map { |group| group.map(&:low).sum / group.size }

      groups.each do |group|
        average = group.map(&:low).sum / group.size
        find_or_create_by!(ticker: instrument.ticker, value: average.round(1), kind: "10d-low") do |level|
          level.dates = group.map(&:date)
          level.accuracy = 0.02
        end
      end

      nil
    end
  end
end

__END__

PriceLevel.search instr('DOCU')

instr('DOCU').candles.day.where(date: Date.parse('2021-06-05')..Date.current).count
