class PriceLevelHit < ApplicationRecord
  belongs_to :level, class_name: 'PriceLevel'
  belongs_to :instrument, foreign_key: 'ticker'

  DELTA = 0.02

  class << self
    def analyze(instrument)
      curr = instrument.yesterday_candle
      return if not curr

      prev = curr.previous

      instrument.levels.order(:value).each do |level|
        if is_nearby = curr.range_with_delta(DELTA).include?(level.value)
          is_exact = is_nearby && curr.range.include?(level.value)
          kind = is_exact ? 'on-level' : 'near-level'
          find_or_create_by! ticker: instrument.ticker, date: curr.date, level: level, level_value: level.value, kind: kind
        end
      end
    end

    def analyze_all
      Instrument.all.abc.each { |inst| analyze inst }
    end
  end
end

__END__
PriceLevelHit.analyze_all
