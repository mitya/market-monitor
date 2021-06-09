class PriceLevelHit < ApplicationRecord
  belongs_to :level, class_name: 'PriceLevel'
  belongs_to :instrument, foreign_key: 'ticker'

  DELTA = 0.01

  def loose? = !exact?

  before_validation do
    self.instrument ||= level&.instrument
    self.level_value ||= level&.value
    self.important = level.important if important == nil
  end

  class << self
    def analyze(instrument)
      curr = instrument.yesterday_candle
      return if not curr

      prev = curr.previous
      recent = curr.previous_n(10)
      recent_ref = recent[-4]

      instrument.levels.order(:value).each do |level|
        if is_nearby = curr.range_with_delta(DELTA).include?(level.value)
          exact = is_nearby && curr.range.include?(level.value)
          delta = exact ? 0 : DELTA
          was_on_level_recently = recent.any? { |candle| candle.range_with_delta(delta).include?(level.value) }
          kind = 'level'

          if prev
            if prev > curr && prev.close > level.value_plus(delta)
              kind = was_on_level_recently ? 'retest-down' : 'fall'
            elsif prev < curr && prev.close < level.value_plus(exact ? 0 : -DELTA)
              kind = was_on_level_recently ? 'retest-up' : 'rise'
            end
          end

          record! level: level, date: curr.date, kind: kind, exact: exact
        end
      end

      where(date: MarketCalendar.prev(curr.date)).each do |yday|
        if curr.up? && curr.close > yday.level.value_plus(DELTA)
          kind = 'rebound-up' # or just pass through
        elsif curr.down? && curr.close < yday.level.value_plus(-DELTA)
          kind = 'rebound-down'
        end

        record! level: yday.level, date: curr.date, kind: kind
      end
    end

    def analyze_all
      Instrument.all.abc.each { |inst| analyze inst }
    end

    def record!(level:, date:, kind:, **attrs)
      puts "#{level.ticker.ljust 8} hit level #{level.value} #{kind}"
      find_or_create_by! level: level, date: date, kind: kind, **attrs
    end
  end
end

__END__
PriceLevelHit.analyze_all

level
fall
rise
rebound-up/down (was on level in 6c, tested level, closed up)
